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
