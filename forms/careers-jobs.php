<?php
declare(strict_types=1);

require_once __DIR__ . '/careers-lib.php';

careers_ensure_storage();

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
  careers_respond(405, ['message' => 'Method not allowed.']);
}

$jobs = careers_load_jobs();
$activeJobs = array_values(array_filter($jobs, static function (array $job): bool {
  return careers_bool_value($job['is_active'] ?? true);
}));

usort($activeJobs, static function (array $a, array $b): int {
  return strcmp((string) ($b['posted_on'] ?? ''), (string) ($a['posted_on'] ?? ''));
});

$payload = array_map('careers_public_job', $activeJobs);
careers_respond(200, ['jobs' => $payload]);

