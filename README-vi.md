# Workspace Manager v1.0.3

**Công cụ triển khai AI Workspace doanh nghiệp** — Một lệnh duy nhất để triển khai đồng bộ workflow, skill và context AI trên toàn tổ chức của bạn.

[![Version](https://img.shields.io/badge/version-1.0.3-blue)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## Cài đặt nhanh

### Bước 1: Clone và cài đặt

**Windows (PowerShell):**

```powershell
git clone https://gitlab.fci.vn/dungnt261/workspace-manager.git
cd workspace-manager
.\install.ps1
```

**macOS / Linux (Bash):**

```bash
git clone https://gitlab.fci.vn/dungnt261/workspace-manager.git
cd workspace-manager
./install.sh
```

> ⚠️ **Windows bị chặn ExecutionPolicy?** Chạy trước: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

> Trình cài đặt tự động phát hiện local files và target CLI/IDE của bạn.

**Người dùng GitLab/GitHub:** Thay URL clone bằng GitLab/GitHub repo của bạn.

### Bước 2: khởi tạo workspace

**Trên folder quản lý Workspace làm việc:**

- Chạy workflow /init-wm
- Wizard tự động nạp `.wm-env.json` từ template đã cài và kiểm tra kết nối.
- Bạn chỉ được hỏi khi một URL không kết nối được — nhập chỉnh sửa nếu cần.
- Nhập các thông tin cá nhân được yêu cầu (Tên, Email, Unit, Department, Role, Product) để tiếp tục.

[📖 Hướng dẫn cài đặt chi tiết →](docs/QUICKSTART-vi.md)

---

## Workspace Manager là gì?

Workspace Manager (WM) là một công cụ CLI dựa trên Git giúp tổ chức triển khai phát triển có hỗ trợ AI một cách nhất quán. WM cung cấp:

- **Cấu hình tập trung** — Tệp `.wm-env.json` chứa tất cả URL repository
- **Context phân lớp** — Phân cấp context L0 (Nghiệp vụ) → L1 (Lĩnh vực) → L2 (Dự án)
- **Workspace theo vai trò** — Tự động tạo cấu trúc thư mục theo từng vai trò (Dev, PO, BA, v.v.)
- **AWF Workflow Framework** — 17 workflow phát triển AI có cấu trúc (plan → deploy)
- **Tool Marketplace** — Đồng bộ công cụ từ kho FCI Skills
- **Đa nền tảng** — Claude Code, Opencode, Codex CLI, Antigravity
- **Hỗ trợ Multi-Role** — Nhập nhiều vai trò cách nhau dấu phẩy (vd: "PO, BA, Tester"), tự động union thư mục
- **Tạo Workspace thông minh** — `create-workspace.ps1` với role normalization, remote/local template fallback

---

## Tính năng mới trong v2

| Tính năng                | Mô tả                                                                                        |
| -------------------------- | ---------------------------------------------------------------------------------------------- |
| `.wm-env.json`           | Cấu hình tập trung — đặt URL GitHub/GitLab một lần, mọi workflow dùng chung          |
| 4 thư mục System         | `00_System/` nay có thêm `policy/`, `prompts/`, `standards/`, `tool-configs/`      |
| Tách riêng AWF           | Workflow/skill AWF nằm trong thư mục riêng — cài theo nhu cầu qua `/sync-awf`         |
| Hỗ trợ 4 target          | Bộ chuyển đổi cho Claude Code, Opencode, Codex CLI, Antigravity                            |
| `wm-folder-naming`       | Quy ước đặt tên thư mục (`00_`, `10_`) và tệp (ISO 8601) nhất quán              |
| Toàn bộ bằng tiếng Anh | Toàn bộ code, workflow, skill viết bằng tiếng Anh (có tài liệu tiếng Việt kèm theo) |

---

## Kiến trúc

```
workspace-manager/                  # Bản thân công cụ (repo này)
├── .wm-env.json                    # Mẫu cấu hình tập trung
├── install.ps1 / install.sh        # Trình cài đặt (chạy từ repo đã clone)
├── workflows/                      # 10 workflow WM (init, sync, save, ...)
├── awf-workflows/                  # 17 workflow AWF (plan, code, test, ...)
├── skills/                         # 4 skill WM
│   └── awf-skills/                 # 6 skill AWF (theo nhu cầu qua /sync-awf)
├── converters/                     # 4 bộ chuyển đổi target
├── scripts/                        # Script tiện ích
├── schemas/                        # JSON schemas
└── templates/                      # Tệp mẫu (kèm .wm-env.json cấu hình mặc định)
```

### Workspace của bạn sau khi chạy `/init-wm`

```
your-project/
├── .wm-env.json                    # Cấu hình của bạn (URL GitHub/GitLab)
├── AGENTS.md / CLAUDE.md           # Tệp persona cho AI
├── 00_System/
│   ├── 01_context/                 # Tệp context L0 + L1
│   ├── 02_policies/                # Chính sách đơn vị/phòng ban
│   ├── 03_prompts/                 # Mẫu prompt dùng chung
│   ├── 04_standards/               # Tiêu chuẩn kiến trúc
│   └── 05_tool-configs/            # Cấu hình công cụ
├── 10_YourProduct-wp/              # Workspace của bạn (đồng bộ hub)
│   ├── 00_context/                 # Context dự án L2
│   ├── 00_temp/                    # Template feature-context.md
│   ├── src/ api/ models/ ...       # Thư mục theo vai trò (tự động tạo)
│   └── docs/ tests/ ...            # (union cho multi-role)
└── .brain/                         # Bộ nhớ phiên làm việc
```

---

## Các target được hỗ trợ

| Target                | Đường dẫn           | Thư mục Workflow    | Bộ chuyển đổi              |
| --------------------- | ----------------------- | --------------------- | ------------------------------ |
| **Claude Code** | `~/.claude/`          | `commands/`         | `convert-to-claude.ps1`      |
| **Opencode**    | `~/.config/opencode/` | `awf-workflows/`    | `convert-to-opencode.ps1`    |
| **Codex CLI**   | `~/.codex/`           | `commands/`         | `convert-to-codex.ps1`       |
| **Antigravity** | `~/.gemini/config/`   | `global_workflows/` | `convert-to-antigravity.ps1` |

> Chỉ những target được phát hiện trên hệ thống của bạn mới hiển thị khi cài đặt.

---

## Tham khảo lệnh

### Workspace Manager (Luôn khả dụng)

| Lệnh                    | Mô tả                                           |
| ------------------------ | ------------------------------------------------- |
| `/init-wm`             | Khởi tạo workspace — wizard chạy lần đầu   |
| `/new-workspace`       | Tạo workspace đồng bộ hub (tiền tố `10_`) |
| `/new-workspace-local` | Tạo workspace local (tiền tố `11_`)          |
| `/update-persona`      | Cập nhật persona AGENTS.md / CLAUDE.md          |
| `/sync-awf`            | Tải workflow + skill AWF                         |
| `/sync-context`        | Đồng bộ tệp context từ context-hub           |
| `/sync-tool`           | Đồng bộ công cụ từ kho FCI Skills           |
| `/save-brain-wm`       | Lưu trạng thái phiên làm việc               |
| `/recap-wm`            | Khôi phục phiên làm việc trước             |
| `/help-wm`             | Hiển thị trợ giúp + tham khảo lệnh          |

### Workflow AWF (Sau khi chạy `/sync-awf`)

| Giai đoạn | Lệnh               | Mô tả                                   |
| ----------- | ------------------- | ----------------------------------------- |
| Plan        | `/plan-awf`       | Thiết kế + lập kế hoạch tính năng  |
| Design      | `/design-awf`     | Thiết kế kỹ thuật                     |
| Visualize   | `/visualize-awf`  | Mockup UI/UX                              |
| Code        | `/code-awf`       | Viết code theo đặc tả                 |
| Run         | `/run-awf`        | Khởi chạy ứng dụng                    |
| Test        | `/test-awf`       | Chạy kiểm thử                          |
| Debug       | `/debug-awf`      | Tìm và sửa lỗi                        |
| Audit       | `/audit-awf`      | Kiểm tra code + bảo mật                |
| Deploy      | `/deploy-awf`     | Triển khai lên production               |
| Refactor    | `/refactor-awf`   | Dọn dẹp code                            |
| Review      | `/review-awf`     | Tổng quan dự án                        |
| Rollback    | `/rollback-awf`   | Hoàn tác thay đổi                     |
| Brainstorm  | `/brainstorm-awf` | Động não ý tưởng thành khái niệm |
| Customize   | `/customize-awf`  | Tùy chỉnh hành vi AI                   |
| Help        | `/help-awf`       | Trợ giúp riêng cho AWF                 |
| Next        | `/next-awf`       | Gợi ý bước tiếp theo thông minh     |
| Init        | `/init-awf`       | Khởi tạo cấu trúc dự án AWF         |

---

## Các lớp Context

Workspace Manager sử dụng kiến trúc context 4 lớp:

| Lớp         | Tệp                                          | Phạm vi                    | Tính bất biến                  |
| ------------ | --------------------------------------------- | --------------------------- | --------------------------------- |
| **L0** | `00_System/01_context/business-context.md`  | Toàn doanh nghiệp         | 🔒 Bất biến                     |
| **L1** | `00_System/01_context/domain-context.md`    | Đơn vị/Phòng ban        | Không được xung đột với L0 |
| **L2** | `[workspace]/00_context/project-context.md` | Sản phẩm/Dự án          | Chỉ chứa context khác biệt    |
| **L3** | `.brain/brain.json`                         | Tri thức phiên làm việc | Tự động sinh                   |

**Luồng kế thừa:** L2 → L1 → L0 luôn được đảm bảo tuân thủ.

---

## Cấu hình `.wm-env.json`

```json
{
  "version": "1.0.3",
  "context_hub": {
    "type": "gitlab",
    "raw_url": "https://raw.githubusercontent.com/your-org/context-hub/main",
    "project_url": "https://gitlab.fci.vn/internal/context-hub",
    "branch": "main",
    "unit": "ai",
    "department": "genai-center"
  },
  "fci_skills": {
    "type": "gitlab",
    "raw_url": "https://raw.githubusercontent.com/your-org/fci-skills/main",
    "project_url": "https://gitlab.fci.vn/internal/fci-skills",
    "branch": "master"
  },
  "workspace_manager": {
    "type": "gitlab",
    "raw_url": "https://raw.githubusercontent.com/your-org/workspace-manager/master",
    "project_url": "https://gitlab.fci.vn/dungnt261/workspace-manager",
    "branch": "master"
  }
}
```

- **type**: `github` hoặc `gitlab`
- **Xác thực GitLab**: Đặt `$env:WM_GITLAB_TOKEN` cho repo riêng tư
- Được tạo trong quá trình `/init-wm` — có thể chỉnh sửa bất kỳ lúc nào

---

## Quy ước đặt tên thư mục & tệp

| Khía cạnh                | Quy tắc                             | Ví dụ                                 |
| -------------------------- | ------------------------------------ | --------------------------------------- |
| Thư mục hệ thống       | Tiền tố `00_`                    | `00_System/`                          |
| Workspace đồng bộ hub   | Tiền tố `10_` + hậu tố `-wp` | `10_OmniSupport-wp/`                  |
| Workspace local            | Tiền tố `11_` + hậu tố `-wp` | `11_MyProject-wp/`                    |
| Tệp theo ngày            | `YYYY-MM-DD-mô-tả-vNN.ext`       | `2026-06-09-report-v01.md`            |
| Ghi đè từ người dùng | Tên rõ ràng → dùng nguyên gốc | Người dùng nói `src/` → `src/` |

---

## Quy trình bắt đầu nhanh

```
Clone + Cài đặt     Khởi tạo           Đồng bộ AWF     Lập kế hoạch    Viết code
~~~~~~~~~~~~~~     ~~~~~~~~           ~~~~~~~~~~~~     ~~~~~~~~~~~~    ~~~~~~~~~~
git clone ...  →   /init-wm       →   /sync-awf   →   /plan-awf   →   /code-awf
.\install.ps1      (tự động config)    (theo nhu cầu)   (tính năng)     (triển khai)
```

[📖 Xem hướng dẫn bắt đầu nhanh đầy đủ →](docs/QUICKSTART-vi.md)

---

## Đóng góp

1. Fork repository
2. Tạo nhánh tính năng
3. Gửi pull request

Xem [SECURITY.md](SECURITY.md) để biết chính sách bảo mật.

---

## Tài liệu

| Tài liệu                             | Ngôn ngữ   |
| -------------------------------------- | ------------ |
| [README.md](README.md)                    | English      |
| [README-vi.md](README-vi.md)              | Tiếng Việt |
| [QUICKSTART.md](docs/QUICKSTART.md)       | English      |
| [QUICKSTART-vi.md](docs/QUICKSTART-vi.md) | Tiếng Việt |

---

## Giấy phép

MIT — Copyright (c) 2026 FPT Smart Cloud — GenAI Center
