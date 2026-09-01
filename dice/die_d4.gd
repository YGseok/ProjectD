class_name DieD4
extends RigidBody3D
## D4(정사면체) 물리 다이스 프리팹의 로직.
##
## - 메시/충돌 모양은 코드로 생성한다 (정사면체는 Godot 기본 Mesh 프리미티브에 없음).
## - 재질(DiceMaterial)을 꽂으면 bounce/friction과 충돌 사운드가 그 재질을 따른다.
## - 사운드 에셋이 아직 없어도(impact_sound == null) 크래시 없이 조용히 스킵한다
##   (STATUS.md 큐 1: "사운드 에셋이 없다면 임시 플레이스홀더로 배선만 맞출 것").

@export var material: DiceMaterial
@export var die_size: float = 0.3

const IMPACT_COOLDOWN := 0.08
const MIN_IMPACT_SPEED := 0.5

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _last_impact_time := -1000.0


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	_build_mesh_and_collision()
	_apply_material()
	body_entered.connect(_on_body_entered)


## 정사면체(D4) 메시 + 볼록 충돌 모양을 생성한다.
## 정점은 정육면체의 교대 꼭짓점 4개를 쓰는 표준 정사면체 좌표를 die_size로 스케일한 것.
func _build_mesh_and_collision() -> void:
	var h := die_size
	var verts := PackedVector3Array([
		Vector3(h, h, h),
		Vector3(h, -h, -h),
		Vector3(-h, h, -h),
		Vector3(-h, -h, h),
	])
	var faces := [
		[0, 1, 2],
		[0, 3, 1],
		[0, 2, 3],
		[1, 3, 2],
	]

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		var a: Vector3 = verts[face[0]]
		var b: Vector3 = verts[face[1]]
		var c: Vector3 = verts[face[2]]
		var normal := (b - a).cross(c - a).normalized()
		st.set_normal(normal)
		st.add_vertex(a)
		st.set_normal(normal)
		st.add_vertex(b)
		st.set_normal(normal)
		st.add_vertex(c)
	_mesh_instance.mesh = st.commit()

	var shape := ConvexPolygonShape3D.new()
	shape.points = verts
	_collision_shape.shape = shape


func _apply_material() -> void:
	if material == null:
		return
	var phys_mat := PhysicsMaterial.new()
	phys_mat.bounce = material.bounce
	phys_mat.friction = material.friction
	physics_material_override = phys_mat
	if material.impact_sound != null:
		_audio_player.stream = material.impact_sound


func _on_body_entered(_body: Node) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_impact_time < IMPACT_COOLDOWN:
		return
	if linear_velocity.length() < MIN_IMPACT_SPEED:
		return
	_last_impact_time = now
	if _audio_player.stream == null:
		return
	_audio_player.pitch_scale = randf_range(0.9, 1.1)
	_audio_player.play()
