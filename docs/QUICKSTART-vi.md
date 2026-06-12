# Hướng dẫn bắt đầu nhanh — Sẵn sàng trong 5 phút

Bắt đầu với Workspace Manager v2 chỉ trong chưa đầy 5 phút.

---

## Điều kiện tiên quyết

- **Git** 2.x trở lên
- **PowerShell 5.1+** (Windows) hoặc **Bash** (macOS/Linux)
- Tài khoản GitHub

---

## Bước 1: Cài đặt (30 giây)

### Windows (PowerShell):

git clone https://gitlab.fci.vn/dungnt261/workspace-manager.git
cd workspace-manager
.\install.ps1

> ⚠️ Bị chặn ExecutionPolicy? Chạy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### macOS / Linux (Bash):

git clone https://gitlab.fci.vn/dungnt261/workspace-manager.git
cd workspace-manager
./install.sh

Trình cài đặt sẽ tự động phát hiện CLI/IDE của bạn (Claude Code, Opencode, Codex, Antigravity) và thiết lập workflow, skill, schema, template và script phù hợp.

**Người dùng GitLab/GitHub:** Thay URL clone bằng GitLab/GitHub repo của bạn. Template config được tự động nạp.

---

## Bước 2: Khởi tạo Workspace (2 phút)

Mở thư mục dự án trong IDE của bạn và chạy:

```
/init-wm
```

Wizard tự động nạp `.wm-env.json` từ template đã cài và kiểm tra tất cả kết nối. Chỉ hỏi khi một URL không kết nối được.

Wizard sẽ hỏi:

1. Kiểm tra context-hub, fci-skills, workspace-manager — hỏi chỉnh sửa nếu có lỗi
2. Tên và email của bạn
3. Đơn vị (vd: "AI Division")
4. Phòng ban (vd: "GenAI Center")
5. Vai trò (vd: "Dev BE", "PO", "BA", "Tester", "SM" — danh sách đầy đủ: PO, PM, BA, Dev FE, Dev BE, Tester, SM, DevOps, Designer, Sales, Operations, Other)

- Nếu có nhiều vai trò, nhập cách nhau dấu phẩy: "PO, BA, Tester" (thư mục tự động union)

6. Sản phẩm (vd: "Omni Support")

Workspace Manager sẽ tự động:

- Cập nhật file `.wm-env.json` với cấu hình của bạn
- Tải các tệp context L0 + L1
- Tạo `00_System/` với policy, prompts, standards, tool-configs
- Tạo thư mục workspace của bạn (`10_YourProduct-wp/`)
- Tự động tạo thư mục theo vai trò (union cho multi-role)
- Tải template feature-context.md vào `temp/`
- Thiết lập tệp persona (AGENTS.md hoặc CLAUDE.md)

---

## Bước 3: Đồng bộ AWF Workflow (30 giây)

Workflow AWF (plan, code, test, deploy, v.v.) không được cài đặt mặc định. Tải về theo nhu cầu:

```
/sync-awf
```

Lệnh này tải 17 workflow AWF + 6 skill AWF và cài đặt cho CLI/IDE của bạn.

---

## Bước 4: Đồng bộ công cụ nhóm (30 giây)

Tải các công cụ được đề xuất cho vai trò của bạn từ kho FCI Skills:

```
/sync-tool
```

Workflow sẽ so sánh công cụ đã cài với kho marketplace, đề xuất công cụ phù hợp với vai trò của bạn, và cài đặt chỉ với một click.

---

## Bước 5: Kiểm tra (30 giây)

```bash
# Kiểm tra tệp context
ls 00_System/01_context/
# Kỳ vọng: business-context.md  domain-context.md

# Kiểm tra thư mục hệ thống
ls 00_System/
# Kỳ vọng: 01_context/  02_policies/  03_prompts/  04_standards/  05_tool-configs/

# Kiểm tra workspace của bạn
ls 10_*-wp/

# Kiểm tra persona
ls AGENTS.md   # hoặc CLAUDE.md
```

---

## Các bước tiếp theo thường dùng

| Mục tiêu                 | Lệnh              |
| -------------------------- | ------------------ |
| Lưu phiên làm việc     | `/save-brain-wm` |
| Khôi phục phiên sau     | `/recap-wm`      |
| Xem tất cả lệnh         | `/help-wm`       |
| Bắt đầu lập kế hoạch | `/plan-awf`      |
| Bắt đầu viết code      | `/code-awf`      |
| Đồng bộ context         | `/sync-context`  |

---

## Làm việc với tính năng mới

Khi bắt đầu một tính năng mới, sử dụng template feature context để AI hiểu rõ yêu cầu của bạn:

```bash
# 1. Copy template từ workspace
cp 10_YourProduct-wp/00_temp/feature-context.md docs/features/my-feature.md

# 2. Điền thông tin tính năng (tên, mô tả, phạm vi, tiêu chí chấp nhận)
# 3. Prompt AI với file đã điền
```

> "Đọc docs/features/my-feature.md và giúp tôi triển khai tính năng này"

Template được tự động copy vào `[workspace]/00_temp/` khi tạo workspace. Bạn có thể đặt file đã điền ở bất cứ đâu trong dự án — AI sẽ đọc theo yêu cầu.

---

## Xử lý sự cố

| Triệu chứng                          | Cách khắc phục                                                                                                                                                                                                 |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `install.ps1` bị chặn              | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`                                                                                                                                                    |
| Không tìm thấy `/init-wm`         | Chạy lại script cài đặt                                                                                                                                                                                      |
| Tệp context trống                    | Chạy `/sync-context` hoặc chạy lại `/init-wm`                                                                                                                                                             |
| `/sync-awf` báo "chưa khởi tạo"  | Chạy `/init-wm` trước                                                                                                                                                                                        |
| Không tìm thấy lệnh AWF            | Chạy `/sync-awf` sau `/init-wm`                                                                                                                                                                              |
| Cần GitLab token                      | Đặt biến môi trường `$env:WM_GITLAB_TOKEN`                                                                                                                                                                |
| Thư mục vai trò không được tạo | Kiểm tra tên vai trò khớp danh sách hợp lệ (PO, PM, BA, Dev FE, Dev BE, Tester, SM, DevOps, Designer, Sales, Operations). Chạy lại `/init-wm` để tạo workspace qua script `create-workspace.ps1`. |
| Thiếu feature-context.md              | Script tự động tải từ context-hub. Nếu offline, template cục bộ được dùng. Chạy `/sync-context` để cập nhật.                                                                                   |

---

## Thành quả bạn nhận được

```
your-project/
├── .wm-env.json                    # Cấu hình tập trung v2
├── AGENTS.md / CLAUDE.md           # Persona cho AI
├── 00_System/
│   ├── 01_context/                 # Context L0 + L1
│   ├── 02_policies/                # Chính sách đơn vị
│   ├── 03_prompts/                 # Mẫu prompt
│   ├── 04_standards/               # Tiêu chuẩn kiến trúc
│   └── 05_tool-configs/            # Cấu hình công cụ
├── 10_YourProduct-wp/              # Workspace của bạn
│   ├── 00_context/                 # Context dự án L2
│   ├── 00_temp/                    # Template feature context
│   ├── src/ api/ models/ ...       # Thư mục theo vai trò (tự động)
│   ├── docs/                       # Thư mục PO/PM/BA (tự động)
│   └── tests/                      # Thư mục Tester (tự động)
└── .brain/                         # Bộ nhớ phiên làm việc
```

---

## Nhận trợ giúp

- Tài liệu đầy đủ: [README-vi.md](../README-vi.md)
- Báo cáo lỗi: https://gitlab.fci.vn/dungnt261/workspace-manager/-/issues
- Trợ giúp từ AI: chạy `/help-wm` trong bất kỳ workspace nào
