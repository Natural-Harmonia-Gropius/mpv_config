import vapoursynth as vs
from vapoursynth import core

CLIP = video_in  # 原始帧（队列）
W = video_in_dw  # 原始帧宽度
H = video_in_dh  # 原始帧高度
FPS = container_fps  # 原始帧率
FREQ = display_fps  # 屏幕刷新率

VW = 1920  # 目标缩放宽度
VH = 1080  # 目标缩放高度

USE_RIFE = False  # 是否要使用RIFE预处理
USE_NVOF = False  # 是否要使用NVOF预处理
USE_MVTL = False  # 是否要使用MVTools预处理

OFPS = 59.940  # 目标帧率
ADAPTIVE_OFPS = True  # 自适应目标帧率，开启后输出帧率将被设置为：最小值(最大值(目标帧率, 双倍原始帧率, 半屏幕刷新率), 屏幕刷新率)

SP = """{ gpu: 1 }"""  # https://www.svp-team.com/wiki/Manual:SVPflow
AP = """{
    block: { w: 32, h: 16, overlap: 2 },
    main: {
        levels: 5,
        search: {
            type: 4, distance: -12,
            coarse: { type: 4, distance: -1, trymany: true, bad: { range: 0 } }
        },
        penalty: { lambda: 3.33, plevel: 1.33, lsad: 3300, pzero: 110, pnbour: 50 }
    },
    refine: [{ thsad: 400 }, { thsad: 200, search: { type: 4, distance: -4 } }]
}"""
FP = """{
    gpuid: %d, rate: { num: %d, den: %d, abs: %s },
    algo: 23, mask: { cover: 80, area: 30, area_sharp: 0.75 },
    scene: { mode: 0, limits: { scene: 6000, zero: 100, blocks: 40 } }
}"""


def main(
    clip=CLIP,
    fps=FPS,
    ofps=OFPS,
):
    if FREQ - FPS < 2:
        raise Warning("Interpolation is not necessary.")

    if VW and VH:
        clip = fit_scale_down(clip, VW, VH)

    if USE_RIFE:
        clip, fps = rife(clip, fps)

    if USE_NVOF:
        clip, fps = svpflow_nvof(clip, fps)

    if USE_MVTL:
        clip, fps = mvtools(clip, fps)

    if ADAPTIVE_OFPS:
        ofps = min(max(OFPS, fps * 2, FREQ / 2), FREQ)

        if FREQ - ofps < 2:
            ofps = FREQ

    clip, fps = svpflow(clip, fps, SP, AP, FP, round(ofps) * 1000, 1001)

    return clip


def fit_scale_down(clip, viewport_width=1920, viewport_height=1080, step=4):
    width = clip.width
    height = clip.height

    ratio = max(width / viewport_width, height / viewport_height)

    if ratio <= 1:
        return clip

    width = round(width / ratio / step) * step
    height = round(height / ratio / step) * step

    clip = clip.resize.Spline36(width=width, height=height)

    return clip


def to_yuv420(clip):
    if clip.format.id == vs.YUV420P8:
        clip8 = clip
    elif clip.format.id == vs.YUV420P10:
        clip8 = clip.resize.Bicubic(format=vs.YUV420P8)
    else:
        clip = clip.resize.Bicubic(format=vs.YUV420P10)
        clip8 = clip.resize.Bicubic(format=vs.YUV420P8)
    return clip, clip8


def svpflow(
    clip,
    fps,
    super_param="{ gpu: 1 }",
    analyse_param="{}",
    flow_param="{ gpuid: %d, rate: { num: %d, den: %d, abs: %s } }",
    fp_num=2,
    fp_den=1,
    fp_abs="auto",
    fp_gpuid=0,
):
    quo = fp_num / fp_den

    if fp_abs == "auto":
        if quo > fps:
            fp_abs = "true"
        else:
            fp_abs = "false"

    if fp_abs == "true":
        ofps = quo
    elif fp_abs == "false":
        ofps = quo * fps
    else:
        raise Exception('typeof abs must be <"auto" | "true" | "false">')

    flow_param = flow_param % (fp_gpuid, fp_num, fp_den, fp_abs)

    clip, clip8 = to_yuv420(clip)
    svp_super = core.svp1.Super(clip8, super_param)
    svp_param = svp_super["clip"], svp_super["data"]
    svp_analyse = core.svp1.Analyse(*svp_param, clip, analyse_param)
    svp_param = *svp_param, svp_analyse["clip"], svp_analyse["data"]
    clip = core.svp2.SmoothFps(clip, *svp_param, flow_param, src=clip, fps=fps)
    return clip, round(ofps, 3)


def svpflow_nvof(clip, fps, super_param="{ gpu: 1 }"):
    clip, clip8 = to_yuv420(clip)
    clip = core.svp2.SmoothFps_NVOF(
        clip, super_param, nvof_src=clip8, src=clip, fps=fps
    )
    return clip, fps * 2


def mvtools(
    clip, fps, multiplier=2, blocksize=2**4, th_diff=8 * 8 * 7, th_changed=14
):
    clip = core.std.AssumeFPS(clip, fpsnum=fps * 1e6, fpsden=1e6)
    mv_super = core.mv.Super(clip, pel=2, hpad=blocksize, vpad=blocksize)
    mv_forward = core.mv.Analyse(
        mv_super, blksize=blocksize, isb=False, chroma=True, search=3, searchparam=2
    )
    mv_backward = core.mv.Analyse(
        mv_super, blksize=blocksize, isb=True, chroma=True, search=3, searchparam=2
    )
    clip = core.mv.FlowFPS(
        clip,
        mv_super,
        mv_backward,
        mv_forward,
        num=fps * multiplier * 1000,
        den=1000,
        mask=0,
        thscd1=th_diff,
        thscd2=th_changed,
    )
    return clip, fps * multiplier


def rife(
    clip,
    fps,
    gpu_id=0,
    gpu_thread=2,
    model=9,
    multiplier=2.0,
    tta=False,
    uhd=False,
    sc_threshold=0.2,
    skip_threshold=60.0,
):
    pixel_format = clip.format.id
    signal_range = clip.get_frame(0).props._ColorRange
    if sc_threshold:
        clip = clip.misc.SCDetect(threshold=sc_threshold)
    clip = clip.resize.Bicubic(format=vs.RGBS, matrix_in=1)
    clip = clip.rife.RIFE(
        model=model,
        multiplier=multiplier,
        tta=tta,
        uhd=uhd,
        gpu_id=gpu_id,
        gpu_thread=gpu_thread,
        sc=bool(sc_threshold),
        skip=bool(skip_threshold),
        skip_threshold=skip_threshold,
    )
    clip = clip.resize.Bicubic(
        format=pixel_format, matrix=1, range=1 - signal_range or None
    )
    return clip, fps * multiplier


main().set_output()
