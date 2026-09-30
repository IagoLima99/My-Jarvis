# My Jarvis

Implantação local do OpenJarvis com Ollama, conversa contínua por voz, Faster-Whisper e Kokoro TTS em português brasileiro.

## Iniciar

No Windows, clique com o botão direito em `Start-My-Jarvis.ps1` e selecione **Run with PowerShell**. Ele:

1. inicia o Docker Desktop, se necessário;
2. verifica o Ollama nativo em `127.0.0.1:11434`;
3. baixa o OpenJarvis oficial em `OpenJarvis/` na primeira execução;
4. cria uma chave local em `.env` na primeira execução;
5. inicia somente o projeto Docker `openjarvis_local`;
6. abre `http://127.0.0.1:18444/`.

Na primeira abertura, clique em **Iniciar conversa** e permita o microfone. Depois disso, a tela detecta sua pausa, envia a fala, reproduz a resposta e volta a escutar automaticamente.

## Componentes locais

- Ollama nativo: `qwen2.5-coder:14b`, em `127.0.0.1:11434`.
- STT: Faster-Whisper `base` em CPU `int8`.
- TTS: Kokoro, voz brasileira `pf_dora`.
- Interface de voz: `127.0.0.1:18444`.
- Dashboard OpenJarvis: `127.0.0.1:18443`.

## WSL

`wsl/ollama-compose.yml` é a configuração versionada do serviço Ollama encontrado em `~/ollama_service`. Ela é opcional: o inicializador Windows não a inicia para não disputar a porta `11434` com o Ollama nativo.

## Desktop nativo (opcional)

`openjarvis-config.windows.toml` e `patches/openjarvis-tauri-local-port.patch` preservam a configuração do Desktop Windows usada neste ambiente. O caminho recomendado continua sendo Docker, pois a política Smart App Control bloqueou os binários temporários da compilação Rust nativa.

## Segurança e dados não versionados

`.env`, modelos, cache Hugging Face, volumes Docker, logs e o clone do OpenJarvis são ignorados. Nenhuma chave ou modelo é enviado ao GitHub. Os containers `backprime` e `rpa-controlcenter` não fazem parte desta composição e não são tocados pelo script.
