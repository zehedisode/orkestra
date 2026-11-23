# orkestra

## Ne yapar

OpenCode tabanlı bir orkestratör ile Codex, Claude Code ve Crush alt ajanlarını tek `worker` komutunda birleştirir. Orkestratör görevi dağıtır, alt ajanlar kendi uzmanlık alanında çalışır ve her koşu varsayılan olarak `~/.agent/runs/` altında kaydedilir.

## Gereksinimler

- Python 3, Node.js ve git.
- OpenCode (orkestratör) ile Codex CLI, Claude Code ve Crush (alt ajanlar).
- OpenCode Go ve Command Code erişimi: `OPENCODE_GO_KEY`, `COMMANDCODE_API_KEY`.
- Yerel model veya paralel iş yükü için önerilen 12 GB+ RAM; `worker doctor` bunu uyarı olarak kontrol eder.

## Tek promptla kurulum

[prompts/install.md](prompts/install.md) içindeki promptu ajanına yapıştır. Prompt sırayla repoyu klonlar, `bash install.sh` çalıştırır, eksik anahtarları sorar ve `worker doctor` ile doğrular.

## Elle kurulum

Repo kökünde:

```bash
bash install.sh
```

`install.sh`; `worker` ve `worker-mcp` için `~/.local/bin` bağlantısı kurar, `mcp[cli]` bağımlılığını kurar, OpenCode/Crush yapılandırmalarını ve `~/.agent/AGENTS.md` dosyasını yazar. Ajan CLI'lerini kurmaz.

Codex ve Claude Code yapılandırmaları örnek olarak gelir. Mevcut dosyaları yedekleyip kopyala:

```bash
mkdir -p ~/.codex ~/.claude
cp config/codex.config.toml.example ~/.codex/config.toml
cp config/claude.settings.json.example ~/.claude/settings.json
```

## Anahtarlar

- `OPENCODE_GO_KEY`: [OpenCode Console](https://opencode.ai/console/go) üzerinden Go aboneliği ve kişisel API anahtarı. Oturumda `export OPENCODE_GO_KEY="..."`; kalıcı kullanım için `~/.config/opencode-go-proxy.env` içine `OPENCODE_GO_KEY=...` yaz ve `chmod 600` uygula.
- `COMMANDCODE_API_KEY`: [Command Code API anahtarları](https://commandcode.ai/settings/keys). `commandcode login` da anahtarı `~/.commandcode/auth.json` dosyasına yazar. Alternatif olarak `export COMMANDCODE_API_KEY="..."` kullanılabilir.

Anahtarı repoya, `AGENTS.md` dosyasına veya komut geçmişine yazma. `worker doctor` iki anahtarı da kontrol eder.

## Komutlar

```bash
worker ask "..."       # OpenCode orkestratör; görevi alt ajanlara dağıtır
worker code "..."      # Codex; kod/dosya değişikliği
worker plan "..."      # Claude; salt-okunur plan ve analiz
worker review "..."    # Claude; salt-okunur kod inceleme
worker status          # ajan, model ve anahtar durumu
worker runs -n 20      # son koşular
```

Ortak bayraklar: `-C/--dir`, `-w/--worktree`, `--read-only`/`--write`, `-m/--model`, `--timeout`, `--json`, `--quiet`. Tam liste: `worker --help`.

## Mimari

```text
Kullanıcı
  └─ worker (CLI facade)
       └─ opencode / orkestra
            ├─ codex  → dosya ve kod değişikliği (workspace-write)
            ├─ claude → plan, analiz, review (read-only)
            └─ crush  → keşif, araştırma, ortam kontrolü
                 ↑
           worker-mcp: delegate_codex / delegate_claude / delegate_crush
```

`AGENTS.md` ortak çalışma sözleşmesidir; orkestratör dosya yazmaz, dosya işlerini Codex'e devreder. `worker init` sözleşmeyi projeye kopyalar, `CLAUDE.md` buna symlink olur. Ayrıntı: [docs/architecture.md](docs/architecture.md).

## Güvenlik

- Orkestratörün `edit` ve `bash` izni kapalıdır; dosya oluşturma, düzenleme ve silme `delegate_codex` üzerinden yürür.
- Codex varsayılan olarak `workspace-write` çalışır; `-w` ayrı bir git worktree açar. `plan` ve `review` salt-okunurdur.
- Anahtarlar ortamdan veya kullanıcıya ait yerel dosyalardan okunur; `install.sh` sırları repoya yazmaz. `.env` ve koşu çıktıları `.gitignore` kapsamındadır.
- `AGENTS.md`; sır yazmama, geri dönüşsüz komutlarda onay ve küçük diff kurallarını taşır.

## Sorun giderme

- `worker: command not found` → `export PATH="$HOME/.local/bin:$PATH"` ve shell profilini güncelle.
- `worker doctor` eksik ajan veya anahtar gösteriyor → ilgili CLI'yi kur, anahtarı yukarıdaki yolla tanımla. Yerel model kullanmıyorsan RAM uyarısı bilgilendirmedir.
- `401`/`403` veya `OPENCODE_GO_KEY yok` → Go aboneliğini, anahtarı ve `~/.config/opencode-go-proxy.env` izinlerini (`600`) kontrol et.
- Codex veya Claude yapılandırma hatası → `config/*.example` dosyalarını yedekleyerek kopyala.
- Zaman aşımı, `oom` veya eksik çıktı → görevi böl, `--timeout` artır veya eşzamanlı ajan sayısını düşür. `worker runs` ve `~/.agent/runs/<run>/meta.json` dosyasına bak.
- Ajan soru soramıyorsa → her koşu tek seferliktir ve stdin kapalıdır; görevi tüm bağlamıyla tek mesajda ver.

## Lisans

MIT — [LICENSE](LICENSE).
