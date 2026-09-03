class_name ProceduralSound
extends RefCounted
## 실제 오디오 에셋이 없을 때 쓰는 절차적(합성) 플레이스홀더 사운드 생성기.
##
## DESIGN.md는 "재질별로 충돌/구르는 소리가 달라진다"를 요구하지만, 지금은 실제
## 녹음/제작된 사운드 에셋이 하나도 없다(STATUS.md 알려진 이슈 참고). AI는 오디오
## 에셋을 만들 수 없으므로, 최소한 "무음"이 아니라 "짧은 타격음이 실제로 들리는"
## 상태를 만들기 위해 코드로 노이즈 버스트 + 감쇠 엔벌로프를 합성해 AudioStreamWAV로
## 만든다. 재질별 실제 사운드 에셋이 생기면 DiceMaterial.impact_sound를 채워 넣는
## 쪽이 항상 우선한다 (die_d4.gd 참고) — 이 함수는 그 전까지의 임시 대체용이다.

static func make_plastic_impact() -> AudioStreamWAV:
	var sample_rate := 44100
	var duration := 0.05
	var frame_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2) # 16비트 모노 = 프레임당 2바이트

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345 # 매번 같은 "형태"의 타격음이 나오도록 고정 시드
	var prev := 0.0
	for i in frame_count:
		var t := float(i) / float(frame_count)
		var envelope := pow(1.0 - t, 6.0) # 빠르게 감쇠하는 "톡" 느낌
		var noise := rng.randf_range(-1.0, 1.0)
		var sample := (noise + prev) * 0.5 # 단순 저역 통과(스무딩)로 백색소음의 거친 느낌 완화
		prev = noise
		sample *= envelope
		var v := int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
