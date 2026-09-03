class_name Die
extends RigidBody3D
## 물리 다이스 프리팹의 로직. `sides`(면 개수)에 따라 메시/충돌 모양이 달라진다.
##
## - D4/D6/D8/D10은 정확한(위상적으로 올바른) 정다면체 모양을 코드로 생성한다
##   (Godot 기본 Mesh 프리미티브에는 D4/D8/D10이 없고, D6은 BoxMesh로 표현 가능).
##   D10은 실제 주사위와 같은 "정오각 사다리 십이면체(pentagonal trapezohedron)"
##   구조(꼭짓점 차수 5/3, 연꼴 면 10개)를 따른다.
## - D12 등 아직 다루지 않은 다면체는 둥근 형태(SphereMesh)로 근사한다 — 이 프로젝트의
##   물리 다이스는 착지한 면을 읽어 실제 판정값을 정하지 않는 순수 연출용이라
##   (STATUS.md "알려진 이슈: 물리 다이스의 착지 면과 실제 판정값이 무관함" 참고)
##   "정확한 다면체 모양"보다 "다이스가 더 커/둥글게 보여 개조가 체감된다"는 시각적
##   구분을 우선했다. 정확한 D12 지오메트리가 필요해지면 `_build_rounded_polyhedron()`
##   호출 자리만 교체하면 됨.
## - 재질(DiceMaterial)을 꽂으면 bounce/friction과 충돌 사운드가 그 재질을 따른다.
## - 실제 사운드 에셋(impact_sound)이 없으면 `ProceduralSound`로 합성한 임시 타격음을
##   대신 재생한다 (완전 무음보다 손맛 검증이 가능한 편이 낫다고 판단 — 실제 에셋이
##   생기면 material.impact_sound를 채우는 쪽이 항상 우선한다).

@export var material: DiceMaterial
@export var die_size: float = 0.3
## 면 개수. DiceBag의 다이스별 face 배열 길이(faces.size())와 맞춰서 넣으면
## 실제 개조 결과(D4->D6 승급 등)가 물리 다이스 모양에도 반영된다.
@export var sides: int = 4
## 알파가 0보다 크면 이 색으로 메시를 덮어씌운다 (몬스터별 다이스 색 구분용).
## 알파 0(기본값)이면 원래 메시 재질(흰색 계열)을 그대로 쓴다.
@export var color_override: Color = Color(0, 0, 0, 0)

const IMPACT_COOLDOWN := 0.08
const MIN_IMPACT_SPEED := 0.5

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _last_impact_time := -1000.0

## 모든 Die 인스턴스가 공유하는 합성 폴백 사운드(재질에 실제 에셋이 없을 때 사용).
## 매 다이스마다 새로 합성하면 낭비이므로 한 번만 만들어 캐시한다.
static var _fallback_impact_sound: AudioStreamWAV


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	_build_mesh_and_collision()
	_apply_material()
	body_entered.connect(_on_body_entered)


func _build_mesh_and_collision() -> void:
	match sides:
		4:
			_build_tetrahedron()
		6:
			_build_cube()
		8:
			_build_octahedron()
		10:
			_build_pentagonal_trapezohedron()
		_:
			_build_rounded_polyhedron()
	if color_override.a > 0.0:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_override
		_mesh_instance.material_override = mat


## 정사면체(D4) 메시 + 볼록 충돌 모양. 정점은 정육면체의 교대 꼭짓점 4개를 쓰는
## 표준 정사면체 좌표를 die_size로 스케일한 것.
func _build_tetrahedron() -> void:
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
	_build_from_triangle_faces(verts, faces)


## 정육면체(D6). Godot 기본 프리미티브(BoxMesh/BoxShape3D)를 그대로 쓴다.
func _build_cube() -> void:
	var h := die_size * 1.6
	var box := BoxMesh.new()
	box.size = Vector3(h, h, h)
	_mesh_instance.mesh = box
	var shape := BoxShape3D.new()
	shape.size = Vector3(h, h, h)
	_collision_shape.shape = shape


## 정팔면체(D8). 6개 축 정점(±X, ±Y, ±Z)을 잇는 8개 삼각형 — 각 면은 자신이
## 속한 팔분면(octant) 방향을 그대로 바깥 법선으로 가지도록 정점 순서를 맞춤.
func _build_octahedron() -> void:
	var h := die_size * 1.5
	var verts := PackedVector3Array([
		Vector3(h, 0, 0), Vector3(-h, 0, 0),
		Vector3(0, h, 0), Vector3(0, -h, 0),
		Vector3(0, 0, h), Vector3(0, 0, -h),
	])
	var faces := [
		[0, 2, 4], [0, 4, 3], [0, 3, 5], [0, 5, 2],
		[1, 4, 2], [1, 2, 5], [1, 5, 3], [1, 3, 4],
	]
	_build_from_triangle_faces(verts, faces)


## 정오각 사다리 십이면체(D10, pentagonal trapezohedron). 실제 D10 주사위와 같은
## 위상 구조: 위/아래 꼭짓점(차수 5) 2개 + 지그재그로 높이가 번갈아 바뀌는 "적도"
## 정점 10개(차수 3) + 연꼴(kite, 사각형) 면 10개. 적도 정점을 높이가 번갈아 뜨는
## 하나의 고리로 두면(별도의 위/아래 두 고리가 아니라) 인접한 위/아래 면끼리 정확히
## 변을 공유하게 된다 — 손으로 정점 인덱스를 나열하기 전에 변 공유 관계를 먼저
## 계산해서 확인한 구조.
func _build_pentagonal_trapezohedron() -> void:
	var r := die_size * 1.3
	var apex_h := die_size * 1.6
	var ring_h := die_size * 0.55
	var verts := PackedVector3Array()
	for i in range(10):
		var angle := i * TAU / 10.0
		var z := ring_h if i % 2 == 0 else -ring_h
		verts.append(Vector3(cos(angle) * r, z, sin(angle) * r))
	var top_apex := verts.size()
	verts.append(Vector3(0, apex_h, 0))
	var bottom_apex := verts.size()
	verts.append(Vector3(0, -apex_h, 0))
	var faces := []
	for i in range(5):
		faces.append([top_apex, (2 * i) % 10, (2 * i + 1) % 10, (2 * i + 2) % 10])
	for i in range(5):
		faces.append([bottom_apex, (2 * i + 1) % 10, (2 * i + 2) % 10, (2 * i + 3) % 10])
	_build_from_polygon_faces(verts, faces)


## D12 등 정확한 지오메트리가 아직 없는 다면체의 임시 근사 형태 (위 클래스
## 주석 참고). 저해상도 구체로 "크고 둥근 다이스"라는 시각적 차별만 준다.
func _build_rounded_polyhedron() -> void:
	var r := die_size * 1.4
	var sphere := SphereMesh.new()
	sphere.radius = r
	sphere.height = r * 2.0
	sphere.radial_segments = 10
	sphere.rings = 5
	_mesh_instance.mesh = sphere
	var shape := SphereShape3D.new()
	shape.radius = r
	_collision_shape.shape = shape


func _build_from_triangle_faces(verts: PackedVector3Array, faces: Array) -> void:
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


## 삼각형이 아닌 평면 볼록 다각형 면(예: 연꼴 사각형)들로 볼록 다면체를 만든다.
## 팬(fan) 방식으로 삼각분할하고, 면의 무게중심이 원점 반대쪽(바깥)을 향하는
## 방향과 계산된 법선이 일치하는지 확인해 승패(winding) 순서를 자동으로 맞춘다
## (원점 중심의 볼록체는 항상 무게중심 방향이 바깥이라는 성질을 이용) — D8에서
## 했던 것처럼 정점 순서를 손으로 검산할 필요가 없어짐.
func _build_from_polygon_faces(verts: PackedVector3Array, faces: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		var ordered: Array = face.duplicate()
		var centroid := Vector3.ZERO
		for idx in ordered:
			centroid += verts[idx]
		centroid /= ordered.size()
		var a: Vector3 = verts[ordered[0]]
		var b: Vector3 = verts[ordered[1]]
		var c: Vector3 = verts[ordered[2]]
		var normal := (b - a).cross(c - a).normalized()
		if normal.dot(centroid) < 0.0:
			ordered.reverse()
		for i in range(1, ordered.size() - 1):
			var p0: Vector3 = verts[ordered[0]]
			var p1: Vector3 = verts[ordered[i]]
			var p2: Vector3 = verts[ordered[i + 1]]
			var n := (p1 - p0).cross(p2 - p0).normalized()
			st.set_normal(n)
			st.add_vertex(p0)
			st.set_normal(n)
			st.add_vertex(p1)
			st.set_normal(n)
			st.add_vertex(p2)
	_mesh_instance.mesh = st.commit()

	var shape := ConvexPolygonShape3D.new()
	shape.points = verts
	_collision_shape.shape = shape


func _apply_material() -> void:
	if material == null:
		_apply_fallback_sound()
		return
	var phys_mat := PhysicsMaterial.new()
	phys_mat.bounce = material.bounce
	phys_mat.friction = material.friction
	physics_material_override = phys_mat
	if material.impact_sound != null:
		_audio_player.stream = material.impact_sound
	else:
		_apply_fallback_sound()


func _apply_fallback_sound() -> void:
	if _fallback_impact_sound == null:
		_fallback_impact_sound = ProceduralSound.make_plastic_impact()
	_audio_player.stream = _fallback_impact_sound


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
