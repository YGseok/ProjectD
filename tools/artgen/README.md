# artgen — Claude + GPT 아트 생성 파이프라인

`docs/art/ART_RESOURCES.md`의 발주서를 OpenAI 이미지 API(GPT 이미지 모델)로 생성하고,
ProjectD 규격으로 후처리한 **후보**를 만든다. 채택·적용·장부 갱신은 아트 스레드(Claude)가 한다.

## 흐름

```
발주서(장부) ─▶ jobs/<job_id>/ (job.env + prompt.txt)  ← Claude가 작성
             ─▶ artgen.sh <job_id> [후보 수]              ← API 호출 + postprocess.gd
             ─▶ out/<job_id>/<시각>/candidate_N.png       ← Claude가 열어서 검수, 사용자에게 후보 제시
             ─▶ adopt.sh <후보> <resources/... 경로>       ← 사용자가 고른 후보 채택
             ─▶ 게임 화면 QA 스크린샷 + 장부 상태 ✅ + git push
```

- `style_full.txt` / `style_face.txt` / `style_icon.txt`: 종류별 공통 화풍 프롬프트(모든 job 앞에 붙음).
- `job.env`: `KIND`(full|face|icon), `SIZE`(1024x1536 | 1024x1024), `REFS`(참고 이미지, 비우면 순수 생성).
  참고 이미지를 넣으면 edits 엔드포인트로 보내 화풍·인물을 맞춘다(표정 세트는 해당 캐릭터 full.png 필수).
- 후처리(`postprocess.gd`, Godot headless): full=세로 1303px·1181×1332 중앙 / face=768×768 / icon=256 + 128.
- `out/`은 git에 올리지 않는다(`.gitignore`). 채택본만 `resources/`로 들어간다.
- `tools/.gdignore`: 이 폴더의 PNG를 Godot가 임포트하지 않게 함.

## 준비 (사용자, 1회)

API 키는 **사용자가 직접** 환경변수로 넣는다(스크립트·Claude는 키를 파일에 쓰거나 출력하지 않음).

```powershell
setx OPENAI_API_KEY "sk-..."
```

설정 후 Claude 데스크톱 앱을 다시 시작해야 새 환경변수가 보인다.
선택: `OPENAI_IMAGE_MODEL`(기본 `gpt-image-1`), `OPENAI_IMAGE_QUALITY`(기본 `medium`, low/medium/high).

## 실행 (보통은 Claude에게 "해적 원화 뽑아줘"처럼 요청)

```bash
bash tools/artgen/artgen.sh pilot_pirate_full 2
bash tools/artgen/adopt.sh tools/artgen/out/pilot_pirate_full/<시각>/candidate_1.png resources/characters/pirate/full.png
```

비용은 장당 과금된다(모델·품질·크기별). 처음엔 후보 수를 1~2로 시험할 것.
