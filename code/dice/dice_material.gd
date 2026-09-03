class_name DiceMaterial
extends Resource
## 다이스 재질 정의. DESIGN.md: "재질(Material)에 따라 충돌/구르는 소리가 달라진다."
##
## 시작 재질은 plastic 하나뿐이지만, 나중에 유리/나무/철제를 추가할 때
## 이 리소스를 하나씩 더 만들고 die_d4.tscn(또는 다른 다이스 프리팹)의
## material 필드만 바꿔 끼우면 되도록 설계함.

@export var material_name: String = "plastic"
@export var bounce: float = 0.3
@export var friction: float = 0.6

## 충돌 시 재생할 사운드. 아직 사운드 에셋이 없으면 비워둔다 —
## die_d4.gd는 impact_sound가 없으면 재생을 스킵하고 조용히 넘어간다
## (배선은 맞춰두고, 나중에 에셋만 채우면 바로 작동).
@export var impact_sound: AudioStream

## 재질별 시각 색(알파 0이면 틴트 없이 메시 기본 모양을 그대로 씀). 몬스터별
## color_override(다이스 색으로 몬스터 구분)가 항상 우선하고, 이 색은 플레이어
## 다이스처럼 color_override가 없을 때만 적용된다 (die_d4.gd `_apply_material()` 참고).
## D8=나무/D10=유리/D12,D20=철제처럼 재질이 sides에 잠정 배정되므로, 지금은 이 색이
## 다이스가 몇 면체인지 짐작하는 시각적 단서 역할도 겸한다.
@export var visual_color: Color = Color(1, 1, 1, 0)
@export var metallic: float = 0.0
@export var roughness: float = 0.6
