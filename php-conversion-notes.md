# PHP Conversion Notes

This site now has a PHP page layer for all former root HTML pages, while the original `.html` files remain in place as source/reference files.

Current PHP pages:

- `index.php`
- `about.php`
- `services.php`
- `projects.php`
- `category-source-inspection.php`
- `careers.php`
- all category, service, project, portfolio, and starter pages converted from `.html` to `.php`

Shared PHP includes:

- `includes/header.php`
- `includes/footer.php`
- `includes/clients-section.php`
- `includes/site.php`

Shared data:

- `data/services.json`
- `data/categories.json`

Conversion utility:

- `tools/convert-html-to-php.ps1`

What changed:

- Shared navigation and footer moved into reusable includes
- Client logos centralized in one PHP data function
- Service and category summary cards centralized in JSON
- All converted PHP pages now use the same shared header and footer
- `careers.php` supports page-specific JS through the shared footer
- Existing `.html` files remain in place, so the migration can continue incrementally or be retired later

Recommended next steps:

1. Install PHP locally and run syntax checks across `s2-ei/*.php`
2. Add URL rewriting so `.php` routes can be served without file extensions
3. Optionally migrate project detail content into JSON and render those pages from a single template
4. Remove or redirect legacy `.html` pages after deployment verification
