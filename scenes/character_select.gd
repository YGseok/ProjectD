extends Node2D
## 캐릭터 선택 화면 (1차 버전).
##
## INBOX.md 피드백("던전에 입장하면, 플레이어블 캐릭터를 선택해야한다. 슬더스와
## 유사" + "일단은 능력 없는 기본 캐릭터. 이쁘장한 여캐 하나 디자인한다")을 반영한
## 최소 구현. 실제 일러스트 에셋은 없어서(아트 파이프라인 필요, 사람 확인 대기 —
## docs/STATUS.md 다음 할 일 큐 참고) 도형으로 조립한 플레이스홀더 실루엣을 대신
## 보여준다. 능력 차별화가 없는 캐릭터 1종뿐이라 선택지는 하나지만, 나중에 캐릭터가
## 늘어날 것을 감안해 "카드 하나 + 시작 버튼" 구조로 만들어 둠.
##
## 흐름: 이 화면이 project.godot의 main_scene이 됨 -> "던전 시작" 버튼 ->
## RunState.reset_run()으로 새 런 시작 -> dungeon_map.tscn.

@onready var start_button: Button = $StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	RunState.reset_run()
	get_tree().change_scene_to_file("res://scenes/dungeon_map.tscn")


## QA 전용: 클릭을 흉내낼 수 없는 자동 스크린샷에서 버튼 동작을 검증하기 위한 래퍼.
func _debug_start_run() -> void:
	_on_start_pressed()
