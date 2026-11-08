# Task: v0.1 实现与开源发布（无人值守）

- **负责人**: 本会话（pi, kelegele）
- **计划**: docs/superpowers/plans/2026-11-09-cli-butler-v0.1.md
- **目标**: 六功能实现（F1→F5→F6→F3→F4→F2）→ 验收 → 发布 GitHub `kelegele/cli-butler`
- **状态**: in-progress

## 预检结论（Task 0）

- 名字查重（2026-11-09）：npm E404 ✓ / GitHub 无同名 ✓ / skills.sh 零命中 ✓ → 定名 `cli-butler`，无需回退 toolbutler
- gh 已登录 kelegele（repo+workflow scope，https 协议）
- shellcheck 0.11.0 已装（/opt/homebrew/bin/shellcheck）

## 里程碑记录

- [x] T0 预检：查重 + shellcheck
- [ ] T1 测试夹具
- [ ] T2 common.sh 原语
- [ ] T3 channels.sh
- [ ] T4 F1 list
- [x] T5 F1 真机验证
  - 真机 `bin/list.sh --kv`：rc=0，2209 行，113s；human 输出分组 brew(706)/npm(9)/pipx(12)/uv(2)/gem(12)/system(1198)/untracked(233)，空组自动跳过
  - 性能改造三件：brew desc bulk 一次调用（原 151 包 × 1s）；whatis 预算（BUTLER_WHATIS_BUDGET，默认 20）+ AW_$name 缓存（key 需标识符消毒，@/-/点不可作变量名）；SEEN/JNAMES 用 case *"$LF$x$LF"* 零 fork 精确匹配（haystack 须 $LF 首尾垫护，$( ) 会剥尾 LF——曾致去重失效 3 连 fail）；realpath_safe 目录规范化 DIRC_ memo + basename/dirname 参数展开去 fork
  - 教训：channel_desc 保持 printf API（测试 $( ) 消费），whatis 回退挪到 add_row 主 shell 层（BASHPID 探测子 shell 在 bash 3.2 不可用——无 BASHPID）；kv 行断言 ${x##*desc=} 会残留尾 TAB，先 ${x//[[:space:]]/}
- [x] T6 F5 refchain
  - commit bb6c99c；tests 47/47
  - 真机：docker 三跳软链链（/usr/local/bin/docker → OrbStack xbin/docker → docker-tools）、owner=brew|managed、last-used=1790066193 ✓；真机 ~/Library/LaunchAgents/ai.deepseek.dsh.web.plist.off 存在且 layer4 grep 机制命中 ✓（node 无 launchd 引用则不误报）
  - 夹具：refchain/bin l3→l2→l1→real/real-tool 三级软链；com.fake.brewsvc.plist 内容改为引用 loose-tool（原 brewsvc 引用对 refchain 用例无意义）；zsh_history 4 行含 l3/loose-tool epoch
  - 教训：layer3 匹配目录要用原始 path 的 dir（${p%/*}），chain walk 后 cur 已漂移到 realpath 目录；测试文件自带 JDIR 后必须重 source common.sh（JOURNAL 在 source 时定死）；macOS awk 对多字节垃圾历史内容会 towc 崩——hist_last_used 已加 LC_ALL=C
- [x] T7 F6 cap
  - commit be84368；tests 47/47；真机 cap git：usage 行 + clone/init/add… 子命令表提取 ✓
- [x] T8 F3 install
  - commit 540964e；tests 47/47；真机验证留待 T11 统一做（dry-run 全矩阵）
- [ ] T9 F4 uninstall（进行中）
- [ ] T10 F2 manage
- [ ] T11 验收加固
- [ ] T12 发布

## 证据

（随任务推进补）
