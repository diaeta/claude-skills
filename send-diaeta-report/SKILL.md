---
name: send-diaeta-report
description: Sends a generated Diaeta PDF report to a patient by email (Gmail via gws CLI) and SMS (Textbee). Use this skill whenever Pierre asks to send, envoyer, sturen, or senden a report to a patient, mentions an email address or phone number in the context of a consultation, or says anything like "envoie le rapport", "send the report", "stuur het rapport", "schick den Bericht". Always confirm both email and SMS with Pierre before sending. Adapts language (fr/en/nl/de) from patient-info.json.
---

# Send Diaeta Report

Sends the patient's PDF report by email + SMS. Always confirm with Pierre before each send.

## Source of truth — repo templates

The canonical templates live inside the Diaeta repo, **not in this skill**. Never inline template copy here: it drifts. The skill orchestrates; the repo owns the content.

| Channel | Template path | Placeholder driver |
|---------|---------------|--------------------|
| Email HTML body | `src/templates/messages/email-report-<lang>.html` | `{consultation_date}`, `{next_appointment_block_html}` |
| Email subject | `SUBJECTS` dict in `send_report.py` (top of file) | none |
| Email signature | Pierre's Gmail `sendAs` signature, fetched at send time | per-language `sendAs` entry |
| SMS body | `src/templates/messages/sms-report-<lang>.txt` | `{consultation_date}` |

`<lang>` ∈ `{fr, en, nl, de}`. If a file for the patient's language is missing, both scripts fall back to `fr`.

If Pierre wants to edit wording, edit the repo file — **not this skill**. The change then flows through automatically on the next send.

## Step 1 — Identify the report

Find the patient ref from context (conversation or current working directory). Locate the latest PDF:

```
patients/<ref>/report-<date>.pdf
```

Read `patients/<ref>/patient-info-<date>.json` to get:
- `language` (fr/en/nl/de) — drives all copy
- `lieu_consultation` — used in optional next-appointment block
- `consultation_date` — substituted into both email and SMS

## Step 2 — Ask for contact details

Ask Pierre (in French, always):
> "Quelle est l'adresse e-mail de la patiente/du patient ? Et le numéro de téléphone (format international, ex. +32 486 030 076) ? Y a-t-il un prochain rendez-vous à mentionner (optionnel) ?"

## Step 3 — Preview and confirm the EMAIL

Render a text preview by:
1. Reading `src/templates/messages/email-report-<lang>.html`.
2. Substituting `{consultation_date}` with `patient-info.json`'s value.
3. If Pierre gave a next-appointment string, substituting `{next_appointment_block_html}` with its plain-text equivalent (otherwise leave blank).
4. Stripping HTML for the preview.
5. Reading the subject from `SUBJECTS[lang]` in `send_report.py`.

Show Pierre:
```
Subject: <subject from SUBJECTS[lang]>
Body preview:
<plain-text of substituted template>
Next appointment: <string or "(aucun)">
```

Then ask:
> "Voici l'e-mail que j'enverrai. Je confirme ?"

## Step 4 — Send the EMAIL

From the repo root (`C:\Users\pierr\Documents\Tasks\v3-safety-net`):

```bash
python send_report.py <patient_ref> <absolute_pdf_path> <to_email> \
  [--next-appointment "mercredi 20 mai 2026 à l'Espace Pluridys"]
```

Arguments are positional (match send_sms.py convention). `send_report.py` handles template loading, signature fetch, MIME assembly (PDF + inline logo + inline portrait), and dispatch via `gws gmail users messages send`. It prints `Email envoyé à <addr> (lang=<lang>, gmail_id=<id>)` on success.

**Path trap** — per `feedback_gws_tempdir.md`, `gws --upload` rejects paths outside the current working directory. `send_report.py` handles this internally via `.tmp_send/`; you do not need to worry about it, but keep the invocation from the repo root.

## Step 5 — Preview and confirm the SMS

Render a text preview by:
1. Reading `src/templates/messages/sms-report-<lang>.txt`.
2. Substituting `{consultation_date}`.

Show Pierre:
```
SMS to: <phone>
<substituted body>
```

Then ask:
> "Voici le SMS. Je confirme ?"

## Step 6 — Send the SMS

```bash
python send_sms.py <patient_ref> <absolute_pdf_path> <to_phone>
```

`send_sms.py` loads Textbee credentials from `.env` (`TEXTBEE_API_KEY`, `TEXTBEE_DEVICE_ID`) and POSTs to `https://api.textbee.dev/api/v1/gateway/devices/<device_id>/sendSMS`. It prints the Textbee batch ID on success.

Phone must be E.164 format (`+32479355551`). If Pierre gives a Belgian number without country code (`0479 35 55 51`), normalize to `+32479355551` before invoking.

## Step 7 — Confirm completion

Report to Pierre:
- Email: sent ✓ (Gmail message ID `<id>`, language `<lang>`)
- SMS: sent ✓ (Textbee batch ID `<id>`)
- Next appointment block: `<str>` or `(aucun)`

If either call fails, surface the exact stderr and stop — do not retry silently, and do not proceed to the other channel without Pierre's instruction.

## Guardrails

- **Sent reports are immutable** — see `feedback_sent_reports_immutable.md`. Once email + SMS are dispatched, never retro-edit the sent PDF, sections, or HTML.
- **No patient names in code or logs** — refer to patients by Biody ref only. Do not echo the recipient email into anything that gets committed (see F-15 audit).
- **Always confirm both channels separately** — Pierre may want to send only one of the two (e.g. no-SMS patients, or reports dispatched at a consultation where SMS isn't relevant).
- **Language fallback** — if `patient-info.json` has `language` not in {fr, en, nl, de}, both scripts fall back to `fr`. Inform Pierre rather than silently sending FR to a DE-speaking patient.

## When templates need to change

Edit the file in the Diaeta repo, not this skill:
- Email HTML → `src/templates/messages/email-report-<lang>.html`
- Email subject → `SUBJECTS` dict at the top of `send_report.py`
- SMS → `src/templates/messages/sms-report-<lang>.txt`
- Signature → Gmail `sendAs` config (via `gws gmail users settings sendAs`)

Commit the change in the repo with `fix(send): update <lang> <channel> template`. The next send run picks it up automatically.
