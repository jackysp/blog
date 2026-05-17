---
title: "Exploring Local LLMs with Ollama: My Journey and Practices"
slug: "exploring-local-llms-with-ollama-my-journey-and-practices"
tags: ['ai', 'llm', 'ollama']
date: 2024-11-27T18:26:14+08:00
draft: false
---

Local Large Language Models (LLMs) have been gaining traction as developers and enthusiasts seek more control over their AI tools without relying solely on cloud-based solutions. In this blog post, I'll share my experiences with **Ollama**, a remarkable tool for running local LLMs, along with other tools like **llamaindex** and **Candle**. I'll also discuss various user interfaces (UI) that enhance the local LLM experience.

---

## Table of Contents

- [Introduction to Ollama](#introduction-to-ollama)
  - [A Popular Choice](#a-popular-choice)
  - [Ease of Use](#ease-of-use)
  - [Built with Golang](#built-with-golang)
- [My Practices with Ollama](#my-practices-with-ollama)
  - [Preferred Models](#preferred-models)
    - [Llama 3.1](#llama-31)
    - [Mistral](#mistral)
    - [Phi-3](#phi-3)
    - [Qwen-2](#qwen-2)
  - [Hardware Constraints](#hardware-constraints)
- [Exploring UIs for Ollama](#exploring-uis-for-ollama)
  - [OpenWebUI](#openwebui)
  - [Page Assist](#page-assist)
  - [Enchanted](#enchanted)
  - [AnythingLLM](#anythingllm)
  - [Dify](#dify)
- [Diving into llamaindex](#diving-into-llamaindex)
- [Experimenting with Candle](#experimenting-with-candle)
- [Conclusion](#conclusion)

---

## Introduction to Ollama

### A Popular Choice

[Ollama](https://github.com/jmorganca/ollama) has rapidly become a favorite among developers interested in local LLMs. Within a year, it has garnered significant attention on GitHub, reflecting its growing user base and community support.

### Ease of Use

One of Ollama's standout features is its simplicity. It's as easy to use as Docker, making it accessible even to those who may not be deeply familiar with machine learning frameworks. The straightforward command-line interface allows users to download and run models with minimal setup.

### Built with Golang

Ollama is written in **Golang**, ensuring performance and efficiency. Golang's concurrency features contribute to Ollama's ability to handle tasks effectively, which is crucial when working with resource-intensive LLMs.

## My Practices with Ollama

### Preferred Models

#### Llama 3.1

I've found that **Llama 3.1** works exceptionally well with Ollama. It's my go-to choice due to its performance and compatibility.

#### Mistral

While **Mistral** also performs well, it hasn't gained as much popularity as Llama. Nevertheless, it's a solid option worth exploring.

#### Phi-3

Developed by Microsoft, **Phi-3** is both fast and efficient. The 2B parameter model strikes a balance between size and performance, making it one of the best small-sized LLMs available.

#### Qwen-2

Despite its impressive benchmarks, **Qwen-2** didn't meet my expectations in practice. It might work well in certain contexts, but it didn't suit my specific needs.

### Hardware Constraints

Running large models on hardware with limited resources can be challenging. On my 16GB MacBook, models around **7B to 8B parameters** are the upper limit. Attempting to run larger models results in performance issues.

## Exploring UIs for Ollama

Enhancing the user experience with UIs can make interacting with local LLMs more intuitive. Here's a look at some UIs I've tried:

### OpenWebUI

[OpenWebUI](https://github.com/OpenWebUI/OpenWebUI) offers a smooth and user-friendly interface similar to Ollama's default UI. It requires Docker to run efficiently, which might be a barrier for some users.

- **Features**:
  - Basic Retrieval-Augmented Generation (RAG) capabilities.
  - Connection to OpenAI APIs.

### Page Assist

[Page Assist](https://chrome.google.com/webstore/detail/page-assist/) is a Chrome extension that I've chosen for its simplicity and convenience.

- **Advantages**:
  - No requirement for Docker.
  - Accesses the current browser page as input, enabling context-aware interactions.

### Enchanted

[Enchanted](https://apps.apple.com/app/enchanted-ai-assistant/id) is unique as it provides an iOS UI for local LLMs with support for Ollama.

- **Usage**:
  - By using **Tailscale**, I can connect it to Ollama running on my MacBook.
  - Serves as an alternative to Apple’s native intelligence features.

### AnythingLLM

[AnythingLLM](https://github.com/Mintplex-Labs/anything-llm) offers enhanced RAG capabilities. However, in my experience, it hasn't performed consistently well enough for regular use.

### Dify

[Dify](https://github.com/langgenius/dify) is a powerful and feature-rich option.

- **Pros**:
  - Easy to set up with an extensive feature set.
- **Cons**:
  - Resource-intensive, requiring Docker and running multiple containers like Redis and PostgreSQL.

## Diving into llamaindex

[llamaindex](https://github.com/jerryjliu/llama_index) is geared towards developers who are comfortable writing code. While it offers robust functionalities, it does have a learning curve.

- **Observations**:
  - Documentation is somewhat limited, often necessitating diving into the source code.
  - The `llamaindex-cli` tool aims to simplify getting started but isn't entirely stable.
    - Works seamlessly with OpenAI.
    - Requires code modifications to function with Ollama.

## Experimenting with Candle

**Candle** is an intriguing project written in **Rust**.

- **Features**:
  - Uses [Hugging Face](https://huggingface.co/) to download models.
  - Simple to run but exhibits slower performance compared to Ollama.

- **Additional Tools**:
  - **Cake**: A distributed solution based on Candle, **Cake** opens up possibilities for scaling and extending use cases.

## Conclusion

Exploring local LLMs has been an exciting journey filled with learning and experimentation. Tools like Ollama, llamaindex, and Candle offer various pathways to harnessing the power of LLMs on personal hardware. While there are challenges, especially with hardware limitations and setup complexities, the control and privacy afforded by local models make the effort worthwhile.

---

*Feel free to share your experiences or ask questions in the comments below!*
