---
name: calendar
description: Google 캘린더 일정 조회·생성·수정·삭제 (Google OAuth 필요)
metadata: {"openclaw": {"requires": {"env": ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN"]}, "emoji": "📅"}}
---

# Google Calendar 스킬

Google Calendar API를 통해 일정을 조회·생성·수정·삭제하는 방법을 안내합니다.

## 인증

- 방식: Google OAuth2
- 필요 환경변수: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`
- API 엔드포인트: `https://www.googleapis.com/calendar/v3`

## 사용 가능한 작업

### 일정 조회
```
GET /calendars/primary/events?timeMin=...&timeMax=...&orderBy=startTime
GET /calendars/primary/events/{eventId}
```
날짜 형식: RFC3339 — `2024-03-15T09:00:00+09:00` (KST = UTC+9)

### 일정 생성
```
POST /calendars/primary/events
{
  "summary": "제목",
  "start": { "dateTime": "...", "timeZone": "Asia/Seoul" },
  "end":   { "dateTime": "...", "timeZone": "Asia/Seoul" },
  "location": "장소",
  "attendees": [{ "email": "..." }]
}
```

### 일정 수정
```
PATCH /calendars/primary/events/{eventId}   부분 수정
PUT   /calendars/primary/events/{eventId}   전체 교체
```

### 일정 삭제
```
DELETE /calendars/primary/events/{eventId}
```
삭제 전 반드시 사용자 확인.

## 주의사항

- 반복 일정 수정 시 `?sendUpdates=all` 파라미터로 참석자 알림 여부 제어
- 시간대는 항상 `Asia/Seoul` 명시
