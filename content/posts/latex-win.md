---
title:  "如何在 Windows 上配置中文 Latex 环境"
date: 2021-03-31T11:13:00+08:00
draft: false
---

## 背景

本来没觉得这是值得写下来的事情，因为，CTex 之前大家用得很顺畅，没想到 CTex 已经从 2016 年后就没更新过了。于是，想找一下当下 2021 年的一个 Windows 上的中文 Latex 替代方案。

## 配置方法

1. 安装 MiKTeX（TexLive 应该也一样），MiKTeX 可以自动下载依赖包，主动安装 ctex 包也可以。
1. 安装 VSCode Latex 插件。
1. 配置 Latex 插件。在知乎找到一份插件配置，很强大，不过也比较复杂。这里稍微简化了一下。

稍微解释一下，这里核心的部分其实就是 recipes 和 tools。tools 是编译工具链，包括使用哪种工具编译，选项用什么，顺序无所谓。recipes 是定义如何组合上述工具来生成最终文档，顺序是有意义的，默认使用第一个。
这里把 XeLaTex 放在了第一，也是因为它编译中文是兼容性最好的，如果用 pdflatex 来编译中文文件，大概率会踩坑。

```json
{
   "latex-workshop.latex.recipes": [
         {
            "name": "XeLaTeX",
            "tools": [
                "xelatex"
            ]
        },
        {
            "name": "latexmk 🔃",
            "tools": [
                "latexmk"
            ]
        },
        {
            "name": "latexmk (latexmkrc)",
            "tools": [
                "latexmk_rconly"
            ]
        },
        {
            "name": "latexmk (lualatex)",
            "tools": [
                "lualatexmk"
            ]
        },
        {
            "name": "pdflatex ➞ bibtex ➞ pdflatex × 2",
            "tools": [
                "pdflatex",
                "bibtex",
                "pdflatex",
                "pdflatex"
            ]
        },
        {
            "name": "Compile Rnw files",
            "tools": [
                "rnw2tex",
                "latexmk"
            ]
        },
        {
            "name": "Compile Jnw files",
            "tools": [
                "jnw2tex",
                "latexmk"
            ]
        },
        {
            "name": "tectonic",
            "tools": [
                "tectonic"
            ]
        }
    ],
    "latex-workshop.latex.tools": [
        {
            "name": "xelatex",
            "command": "xelatex",
            "args": [
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "%DOCFILE%"
            ]
        },
        {
            "name": "latexmk",
            "command": "latexmk",
            "args": [
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-pdf",
                "-outdir=%OUTDIR%",
                "%DOC%"
            ],
            "env": {}
        },
        {
            "name": "lualatexmk",
            "command": "latexmk",
            "args": [
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-lualatex",
                "-outdir=%OUTDIR%",
                "%DOC%"
            ],
            "env": {}
        },
        {
            "name": "latexmk_rconly",
            "command": "latexmk",
            "args": [
                "%DOC%"
            ],
            "env": {}
        },
        {
            "name": "pdflatex",
            "command": "pdflatex",
            "args": [
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "%DOC%"
            ],
            "env": {}
        },
        {
            "name": "bibtex",
            "command": "bibtex",
            "args": [
                "%DOCFILE%"
            ],
            "env": {}
        },
        {
            "name": "rnw2tex",
            "command": "Rscript",
            "args": [
                "-e",
                "knitr::opts_knit$set(concordance = TRUE); knitr::knit('%DOCFILE_EXT%')"
            ],
            "env": {}
        },
        {
            "name": "jnw2tex",
            "command": "julia",
            "args": [
                "-e",
                "using Weave; weave(\"%DOC_EXT%\", doctype=\"tex\")"
            ],
            "env": {}
        },
        {
            "name": "jnw2texmintex",
            "command": "julia",
            "args": [
                "-e",
                "using Weave; weave(\"%DOC_EXT%\", doctype=\"texminted\")"
            ],
            "env": {}
        },
        {
            "name": "tectonic",
            "command": "tectonic",
            "args": [
                "--synctex",
                "--keep-logs",
                "%DOC%.tex"
            ],
            "env": {}
        }
    ],
    "latex-workshop.view.pdf.viewer": "tab"
}
```

4. 创建一个文件夹
5. 使用 VSCode 打开这个文件夹创建一个 .tex 文件，内容写

```tex
\documentclass[UTF8]{ctexart}

\begin{document}
OK，大功告成了。。。
\end{document
```

应该会自动开始编译，中间遇到需要下载依赖确认通过就好。编译后效果如下：

![test](/posts/images/20210331113405.png)
