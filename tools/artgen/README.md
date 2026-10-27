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


## 무료 경로 (기본) — ChatGPT 화면 + Claude 후처리

API는 유료라 기본은 ChatGPT 구독 안에서 생성한다(2026-10-14 사용자 결정: 비용 지출 없음).

1. Claude가 job을 만들고 `bash tools/artgen/prompt.sh <job_id>`로 **붙여넣을 프롬프트 + 첨부할 참고 이미지 경로**를 뽑아 전달.
2. 사용자가 ChatGPT에 참고 이미지를 첨부하고 프롬프트를 붙여넣어 생성 → 마음에 드는 걸 다운로드.
3. 다운로드한 파일을 `tools/artgen/inbox/`에 넣고 Claude에게 알림(파일 이름은 아무거나).
4. Claude가 `bash tools/artgen/ingest.sh <파일> <full|face|icon> <job_id>`로 규격 후보 생성
   (불투명 단색 배경은 자동 제거) → 검수 → `adopt.sh`로 채택 → 화면 QA → 장부 갱신 → push.

`inbox/`와 `out/`은 git에 올리지 않는다.

## 유료 경로 (선택) — OpenAI API
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

- `bg_strict.gd` — 흰 배경 위의 창백한 캐릭터(흰 피부·흰 옷)용 배경 제거. 테두리와 이어진 거의 순백만 지운다. 결과를 `postprocess.gd ... full`에 다시 넣으면 규격(1181×1332)으로 맞춰진다.
- `crop_patch.gd` / `patch_region.gd` — 부분 수정: 고칠 부위만 잘라 GPT에 보내고 결과를 제자리에 합성(그 외 픽셀은 기준본 그대로).
