<?php
declare(strict_types=1);

const CAREERS_DATA_FILE = __DIR__ . '/data/jobs.json';
const CAREERS_APPLICATIONS_FILE = __DIR__ . '/data/applications.json';
const CAREERS_JOBS_UPLOAD_DIR = __DIR__ . '/uploads/jobs';
const CAREERS_RESUMES_UPLOAD_DIR = __DIR__ . '/uploads/resumes';
const CAREERS_MAX_UPLOAD_BYTES = 5242880;

function careers_admin_key(): string {
  $env = getenv('S2_CAREERS_ADMIN_KEY');
  if ($env !== false && trim((string) $env) !== '') {
    return trim((string) $env);
  }
  return 'change-this-admin-key';
}

