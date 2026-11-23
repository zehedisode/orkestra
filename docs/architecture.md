# Mimari

## Genel bakış

`worker`, OpenCode orkestratörünü ve üç alt ajanı tek bir komut satırı arayüzünde toplar. Orkestratör karar verir ve işi MCP araçlarıyla devreder; alt ajanlar ayrı süreçlerde çalışır. Her ajan koşusu bir çalışma dizini, komut satırı, çıktı ve meta veri kaydı üretir.

```text
Kullanıcı
  → worker (Python CLI)
      → opencode run (orkestratör, OpenCode Go modeli)
          → worker-mcp (FastMCP)
              ├─ delegate_codex  → worker run codex  → dosya/kod değişikliği
              ├─ delegate_claude → worker run claude → plan/analiz/review
              └─ delegate_crush  → worker run crush  → keşif/araştırma
```

## Bileşenler

| Bileşen | Görev | Varsayılan sınır |
|---|---|---|
| `bin/worker` | Komutları ayrıştırır, ajan süreçlerini başlatır, çıktıyı kaydeder, worktree ve timeout yönetir. | codex 600 s, claude 420 s, crush/opencode 300 s |
| `bin/worker-mcp` | OpenCode'a `delegate_codex`, `delegate_claude`, `delegate_crush` araçlarını sunar. | Araç çağrısı başına 900 s |
| `opencode` / orkestra | Görevi böler, uygun MCP aracına devreder ve sonucu özetler. | `edit` ve `bash` izni kapalı, 40 adım |
| `codex` | Kod ve dosya değişikliği; test/komut çalıştırma. | `workspace-write` ya da `read-only` sandbox |
| `claude` | Plan, mimari karar, kod inceleme ve ikinci görüş. | Varsayılan salt-okunur |
| `crush` | Araştırma, keşif, uzun dosya/log okuma ve ortam kontrolü. | Varsayılan salt-okunur |
| `commandcode` | Ajan değildir; model API köprüsü ve kimlik doğrulama aracıdır. | `worker status` içinde yönlendirici olarak görünür |

Model yönlendirmesi `~/.config/opencode/opencode.json`, `~/.config/crush/crush.json`, `~/.codex/config.toml` ve `~/.claude/settings.json` üzerinden yapılır. Varsayılan model `deepseek-v4.1-flash` ailesidir; `WORKER_MODEL_OPENCODE`, `WORKER_MODEL_CODEX`, `WORKER_MODEL_CLAUDE` ve `WORKER_MODEL_CRUSH` ile değiştirilebilir.

## Dosya yerleşimi

```text
orkestra/
├── bin/
│   ├── worker              # CLI facade
│   └── worker-mcp          # OpenCode MCP araç sunucusu
├── config/
│   ├── AGENTS.md.tmpl
│   ├── opencode.json.tmpl
│   ├── crush.json.tmpl
│   ├── codex.config.toml.example
│   └── claude.settings.json.example
├── docs/architecture.md
├── prompts/
│   ├── install.md
│   └── usage.md
├── .env.example
├── install.sh
├── LICENSE
└── README.md
```

Çalışma zamanı dosyaları:

- `~/.local/bin/worker` ve `~/.local/bin/worker-mcp`: repo içindeki betiklere symlink.
- `~/.agent/AGENTS.md`: `worker init` için kaynak sözleşme.
- `~/.agent/runs/`: koşu dizinleri; `task.md`, `cmd.txt`, `meta.json`, `output.log`, gerekirse `last-message.md` ve `diff.patch`.
- `~/.agent/worktrees/`: `-w` ile oluşturulan izole git çalışma ağaçları.
- `~/.config/opencode-go-proxy.env` ve `~/.commandcode/auth.json`: anahtar kaynakları; repoya girmez.

`WORKER_HOME` ile `~/.agent` kökü değiştirilebilir. `WORKER_ORCH` yalnızca `worker status` çıktısındaki orkestratör etiketini etkiler; gerçek model `WORKER_MODEL_OPENCODE` ile belirlenir.

## Delegasyon kuralları

Bu kurallar `config/AGENTS.md.tmpl` içindeki sözleşmenin özetidir:

- Dosya oluşturma, düzenleme veya silme içeren her görev `delegate_codex` aracına gider; tek satırlık işler de istisna değildir.
- Plan, mimari karar, kod inceleme ve ikinci görüş `delegate_claude` aracına gider.
- Araştırma, keşif, uzun log/dosya okuma ve ortam kontrolü `delegate_crush` aracına gider.
- Yalnızca sohbet, açıklama ve bilgi soruları orkestratör tarafından doğrudan yanıtlanır.
- Aynı iş iki ajana verilmez. Her devir tek bir işi kapsar; 3+ dosya veya 2+ ayrı konu varsa görev bölünür.
- Her ajan sonucu kısa özet, değişen dosyalar, çalıştırılan test ve varsa `SORU:` etiketiyle bildirir.

CLI kısayolları aynı sınırları korur: `ask` OpenCode'u, `code` Codex'i yazma modunda, `plan` ve `review` Claude'u salt-okunur modda çağırır. `worker run` ajanı elle seçer; `--write` ve `--read-only` varsayılanı geçersiz kılar.

## Sınırlar

### RAM ve eşzamanlılık

Uzak model kullanıldığında model ağırlıkları yerelde yüklenmez; `worker doctor` içindeki 12 GB RAM eşiği yerel model ve ağır paralel iş yükü için uyarıdır. Her alt ajan ayrı bir süreçtir; derleme, test ve birden çok ajan belleği çoğaltır. Kaynak sınırlı makinelerde koşuları sırayla yürüt ve paralel ajan sayısını düşür.

### Tek seferlik koşular

Her ajan çalıştırması bir süreç başlatır, görevi çalıştırır ve çıkar. Facade sohbet geçmişini veya önceki koşunun bağlamını sonraki çağrıya taşımaz; alt ajan oturumları kalıcı olsa bile `worker` bunları resume etmez. Çok adımlı işleri ayrı komutlara böl veya tüm bağlamı görev metnine ekle. `worker ask` tek çağrıda orkestre eder, ancak toplam süresi kendi timeout'u ile sınırlıdır; MCP araçlarının 900 s varsayılanı dış sürecin 300 s sınırını kaldırmaz.

### Soru soramama

Alt süreçlere `stdin=DEVNULL` verilir ve terminal etkileşimi yoktur. Ajanlar kullanıcıya dönüp ek bilgi isteyemez; belirsizlikte varsayım yapıp sonucu `SORU:` etiketiyle bildirmek zorundadır. Bu nedenle görev; hedef dizin, beklenen davranış, kısıtlar ve doğrulama komutunu içermelidir.

### Zaman aşımı ve hata

Timeout aşılırsa süreç öldürülür ve `meta.json` içine `reason: timeout` yazılır. Sinyal veya bellek kaynaklı sonlanmalar `sigterm`/`oom`, diğer sıfır dışı çıkışlar `hata` olarak işaretlenir. Yarım kalan kayıtlar 15 dakika sonra `stale` görünür. `--timeout` ile sınır artırılabilir; ancak çok uzun görevleri küçük parçalara bölmek daha güvenilirdir.

## Güvenlik sınırı

Orkestratörün dosya ve shell araçları kapalıdır; varsayılan delegasyon akışında yazma yetkisi Codex alt sürecindedir. `--write` bilinçli olarak diğer ajanlara da verilebilir. `-w` kullanıldığında değişiklikler ayrı git worktree ve dalında tutulur; `AGENTS.md` kopyalanır, `CLAUDE.md` symlink edilir ve bu dosyalar diff dışında bırakılır. Anahtarlar ortamdan veya kullanıcıya ait yerel dosyalardan (önerilen izin `0600`) okunur; repoya, `AGENTS.md` dosyasına veya loga yazılmaz.
