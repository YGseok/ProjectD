class_name ProceduralSound
extends RefCounted
## 실제 오디오 에셋이 없을 때 쓰는 절차적(합성) 플레이스홀더 사운드 생성기.
##
## DESIGN.md는 "재질별로 충돌/구르는 소리가 달라진다"를 요구하지만, 지금은 실제
## 녹음/제작된 사운드 에셋이 하나도 없다(STATUS.md 알려진 이슈 참고). AI는 오디오
## 에셋을 만들 수 없으므로, 최소한 "무음"이 아니라 "짧은 타격음이 실제로 들리는"
## 상태를 만들기 위해 코드로 노이즈 버스트(+재질에 따라 톤 성분) + 감쇠 엔벌로프를
## 합성해 AudioStreamWAV로 만든다. 재질별 실제 사운드 에셋이 생기면
## DiceMaterial.impact_sound를 채워 넣는 쪽이 항상 우선한다 (die_d4.gd 참고) —
## 이 함수들은 그 전까지의 임시 대체용이다.
##
## 네 재질(플라스틱/나무/유리/철제)을 감(느낌)으로 구별했을 뿐 실제로 "그럴듯하게"
## 들리는지는 사람이 들어봐야 판단 가능한 영역 (INBOX.md 피드백 필요):
## - 플라스틱: 짧고 거친 "톡" (순수 노이즈, 빠른 감쇠)
## - 나무: 더 뭉툭하고 낮은 "퉁" (노이즈를 더 뭉갬 + 살짝 더 긴 감쇠)
## - 유리: 높은 "쨍" + 여운 (고주파 톤 섞고 감쇠를 느리게)
## - 철제: 쇳소리 "챙" + 금속성 여운 (비화성 배음 톤 두 개 섞고 중간 길이 감쇠)


## 노이즈(+선택적으로 톤 성분)를 감쇠 엔벌로프로 감싸 -1..1 범위의 샘플 배열을 만든다.
## - decay_power가 클수록(예: 6) 더 빠르게(날카롭게) 잦아들고, 작을수록(예: 2) 더 길게 "운다".
## - noise_smoothing(0..1)이 클수록 인접 샘플을 더 섞어 노이즈가 거칠지 않고 뭉툭해진다.
## - tone_freqs가 비어있지 않으면 그 주파수들의 사인파를 섞어 "쨍"/"챙" 같은 금속/유리
##   느낌의 톤을 더한다.
static func _synth_impact(duration: float, seed: int, decay_power: float,
		noise_smoothing: float, tone_freqs: Array = []) -> PackedFloat32Array:
	var sample_rate := 44100
	var frame_count := int(sample_rate * duration)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed # 매번 같은 "형태"의 타격음이 나오도록 재질마다 고정 시드
	var samples := PackedFloat32Array()
	samples.resize(frame_count)
	var prev := 0.0
	for i in frame_count:
		var t := float(i) / float(frame_count)
		var time_sec := float(i) / float(sample_rate)
		var envelope := pow(1.0 - t, decay_power)
		var noise := rng.randf_range(-1.0, 1.0)
		var smoothed := noise * (1.0 - noise_smoothing) + prev * noise_smoothing
		prev = noise
		var sample := smoothed
		if tone_freqs.size() > 0:
			var tone := 0.0
			for freq in tone_freqs:
				tone += sin(TAU * float(freq) * time_sec)
			tone /= tone_freqs.size()
			sample = smoothed * 0.4 + tone * 0.6
		sample *= envelope
		samples[i] = clamp(sample, -1.0, 1.0)
	return samples


static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2) # 16비트 모노 = 프레임당 2바이트
	for i in samples.size():
		data.encode_s16(i * 2, int(samples[i] * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	stream.data = data
	return stream


static func make_plastic_impact() -> AudioStreamWAV:
	return _to_wav(_synth_impact(0.05, 12345, 6.0, 0.5))


static func make_wood_impact() -> AudioStreamWAV:
	return _to_wav(_synth_impact(0.08, 23456, 4.0, 0.8))


static func make_glass_impact() -> AudioStreamWAV:
	return _to_wav(_synth_impact(0.18, 34567, 2.0, 0.15, [3200.0, 4400.0]))


static func make_metal_impact() -> AudioStreamWAV:
	return _to_wav(_synth_impact(0.13, 45678, 3.0, 0.25, [1800.0, 2600.0]))
