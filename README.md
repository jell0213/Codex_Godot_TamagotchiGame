# MOMO · 小日子

Godot **4.7.2 stable** 的第一人稱 3D 電子雞原型。主角「毛毛」、盆栽、坐墊與愛心都是 Godot `Image` 即時繪製的 2D 貼圖，在 3D 房間中透過 `Sprite3D` billboard 永遠面向攝影機。地板、地毯、牆面與牆上的裝飾屬於固定背景。毛毛左側的透明快樂罐是實際 3D 圓柱幾何體；橘色液體的體積會隨快樂值線性變化，空罐、半滿與滿罐都能直接看出差異。

不需要外部素材、套件、Spine runtime 或網路服務。開啟 `project.godot`，按 **F6** 執行目前場景或 **F5** 執行專案。

## 操作

| 操作 | 功能 |
| --- | --- |
| 點「點此探索小屋」 | 擷取滑鼠，開始第一人稱探索 |
| WASD / 滑鼠 | 移動 / 環顧；房間與物件有碰撞 |
| 靠近並看向毛毛，按 E | 顯示互動選項，保留目前視角並繼續允許 WASD 移動；距離需在 2.8 公尺內且視線未被遮擋 |
| 按住「撫摸」按鈕或空白鍵 | 持續撫摸，放開停止；需先開啟互動選單 |
| 打招呼 | 播放招呼小跳動與文字，不改變量表 |
| E / 離開 | 結束互動，回到第一人稱探索 |
| Esc | 釋放／擷取游標；互動中按下則關閉選單並釋放游標 |

互動中滑鼠僅操作選單，不會改變角色朝向／俯仰角；WASD 仍可移動。離開互動距離、視線被擋或視窗失焦，都會取消撫摸；結束選單後滑鼠恢復環顧。失焦期間暫停模擬，返回後不自動擷取滑鼠。

## 數值規則

兩個量表範圍都是 0–100。持續撫摸每秒增加 18 撫摸度；只要撫摸度大於 0，不論是否持續撫摸或是否開著互動選單，快樂都會依以下速度累積：

```text
4 + 32 × (撫摸度 / 100)^1.6  點／秒
```

撫摸度越高，快樂累積越快，最高每秒 36 點。停止撫摸後有 1.4 秒緩衝，再每秒減少 3.5 撫摸度；期間仍會繼續產生快樂。撫摸度歸零後停止產生快樂，閒置緩衝已過時，快樂才會每秒減少 5 點。完全沒有撫摸度時不會憑空增加快樂。

快樂滿格會播放 2.2 秒的瞇眼、跳躍、伸縮與愛心動畫。動畫中快樂維持滿格且不重複觸發，結束後**只歸零快樂度**，保留撫摸度。動畫中仍可增加撫摸度；動畫期間不進行閒置衰減。動畫結束後重新計算閒置緩衝；若還有撫摸度，即使不再撫摸，也會再次累積快樂。罐子與 UI 同步顯示快樂滿格、歸零及後續累積。

目前是單次遊玩原型，未加入存檔、離線衰減或實際 Spine 素材。

## 執行與驗證

在此雲端環境，每個 shell 先啟用 4.7.2（系統預裝版仍是 4.6.3）：

```bash
export PATH=/workspace/.godot-environment/bin:$PATH
export XDG_CACHE_HOME=/workspace/.godot-environment/cache
export XDG_DATA_HOME=/workspace/.godot-environment/data
export XDG_CONFIG_HOME=/workspace/.godot-environment/config
cd /workspace/Codex_Godot_TamagotchiGame
godot --version
godot --editor --path .
```

核心自動檢查不需要顯示器：

```bash
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --quit-after 120
```

無介面模式執行 63 項檢查，另明確略過 5 項需滑鼠擷取的移動／視角檢查。要執行完整 68 項，請在有顯示器的環境移除 `--headless`：

```bash
godot --path . --script res://tests/run_tests.gd
```

測試涵蓋累積、加速、閒置緩衝與衰減、上下限、動畫事件、只清空快樂、重複慶祝、不同幀率、場景載入、互動距離／方向／遮擋、按下與放開、失焦取消、原生外觀、UI 錨點，互動中維持視角與實際移動、透明罐液量與上下限，以及實際 WASD 移動、角色／地板碰撞與滑鼠視角。

本次已在 Godot 4.7.2 完成無介面檢查，以及虛擬 X11 顯示器上的完整 68 項檢查（0 失敗）；另透過 Mesa 軟體 OpenGL 實際渲染並檢視待機、互動及開心動畫畫面。這不代表已驗證硬體 GPU、行動裝置、平台匯出或第三方 Spine runtime。

## 專案結構

- `scripts/main.gd`：生成房間、互動條件、輸入與場景組合。
- `scripts/player.gd`：第一人稱移動、環顧與碰撞。
- `scripts/pet_state.gd`：獨立於畫面的雙量表模擬與開心事件。
- `scripts/pet_actor.gd`：連接數值與可替換的角色外觀。
- `scripts/sprite_factory.gd`：用 Godot 內建 Image 生成全部物件貼圖。
- `scripts/happiness_jar.gd`：透明立體罐、刻度、液體與液面的高度同步。
- `scripts/hud.gd`：繁體中文介面、互動選項與數值顯示。
- `scripts/presentation/`：原生演出與可選 Spine 接口。

Spine 的接入方式、版本限制與橋接合約見 [docs/SPINE.md](docs/SPINE.md)。
