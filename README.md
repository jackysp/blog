# Blog

My personal blog built with Hugo and PaperMod theme.

## Features

- Static site generated with Hugo
- Automated build and deployment via GitHub Actions
- MCP-powered publishing workflow for AI agents

## Structure

- `content/posts/` - Blog posts (Markdown files)
- `static/` - Static assets (images, favicons, etc.)
- `themes/PaperMod/` - Hugo theme (submodule)
- `PUBLISHING.md` - Publishing contract for MCP agents

## Publishing

For AI agents publishing via MCP, see `PUBLISHING.md` for detailed guidelines and restrictions.

## Build

```bash
make
```

This runs Hugo to generate the static site in the `public/` directory.

## License

See [LICENSE](LICENSE) file for details.
