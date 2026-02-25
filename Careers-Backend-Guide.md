# Careers Backend Guide (for Arpit)

This project now includes a lightweight PHP backend for Careers:

- Public jobs feed: `forms/careers-jobs.php`
- Admin jobs API: `forms/careers-admin.php`
- Resume submission API: `forms/careers-apply.php`
- Jobs data file: `forms/data/jobs.json`
- Applications data file: `forms/data/applications.json`
- Job PDF uploads: `forms/uploads/jobs/`
- Resume uploads: `forms/uploads/resumes/`

Security note:
- `forms/data/.htaccess` and `forms/uploads/resumes/.htaccess` deny direct web access (Apache).

## 1) Set admin key

Set environment variable on the web server:

`S2_CAREERS_ADMIN_KEY=your-secure-key`

If not set, default fallback key is:

`change-this-admin-key`

Use this key as:

- Header: `X-Admin-Key: <key>` (recommended), or
- Form field: `admin_key=<key>`

## 2) Add new job posting

`POST forms/careers-admin.php`

Form fields:

- `action=add`
- `title` (required)
- `department`
- `location`
- `employment_type`
- `summary`
- `description`
- `is_active` (`1` or `0`)
- `job_pdf` (optional PDF upload)

## 3) Edit job description

`POST forms/careers-admin.php`

Form fields:

- `action=edit`
- `id` (required)
- any editable fields:
  - `title`, `department`, `location`, `employment_type`, `summary`, `description`, `is_active`, `pdf_url`
- optional `job_pdf` (replace existing PDF)

## 4) Delete job posting

`POST forms/careers-admin.php`

Form fields:

- `action=delete`
- `id` (required)

## 5) Upload PDF job descriptions

Include PDF file in `job_pdf` when calling `action=add` or `action=edit`.
Uploaded files are stored in:

`forms/uploads/jobs/`

Frontend links render automatically from each job's `pdf_url`.

## 6) Enable resume submission

`careers.html` resume form posts to:

`forms/careers-apply.php`

Required fields:

- `applicant_name`
- `applicant_email`
- `applicant_phone`
- `resume_file` (`.pdf`, `.doc`, `.docx`)

Optional fields:

- `job_title`
- `job_id`
- `cover_message`

Saved output:

- File upload: `forms/uploads/resumes/`
- Submission record: `forms/data/applications.json`

## 7) PowerShell sample for adding a job

```powershell
$form = @{
  admin_key = "your-secure-key"
  action = "add"
  title = "Materials Tester"
  department = "Materials Testing"
  location = "Signal Hill, CA"
  employment_type = "Full-Time"
  summary = "Field and lab testing support."
  description = "Perform concrete, asphalt, and aggregate testing."
  is_active = "1"
}
Invoke-RestMethod -Method Post -Uri "https://your-domain/forms/careers-admin.php" -Form $form
```

This is ready for Arpit to operate now, and can be extended with authentication/UI controls during your next-weekend review.
