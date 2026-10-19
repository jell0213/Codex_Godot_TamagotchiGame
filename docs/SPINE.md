# 以 Spine 替換原生角色

目前遊戲完全使用 Godot 原生功能。**本專案沒有安裝或假裝提供 Spine runtime**；Godot 原生不直接播放 Spine skeleton。之後需選用支援 Godot 4.7.2 的 Spine runtime，確認其授權，以及 Spine 編輯器匯出版本與 runtime 版本相容。若沒有相容的預編譯 GDExtension，可能需要自行編譯；這不影響目前原生遊戲。

## 分層

`PetState` 只負責數值與 `celebration_started` / `celebration_finished` 事件；`PetActor` 將事件轉給 `PetPresentation`。外觀不得自行清空量表。

可替換外觀需繼承 `PetPresentation`，實作以下方法：

```gdscript
func set_stroking(active: bool) -> void
func set_affection(normalized: float) -> void  # 0–1
func play_celebration() -> void
func finish_celebration() -> void
func play_greeting() -> void
```

## 可選的 2D → 3D 轉接器

已提供 `SpinePetPresentation`：將未來的 Spine `Node2D` 場景放入透明 `SubViewport`，再使用 `Sprite3D` 顯示 viewport texture。`BILLBOARD_ENABLED` 讓角色永遠面向玩家，與遊戲邏輯無關。

1. 安裝適當 runtime，依該 runtime 官方文件匯入 skeleton、atlas、texture，建立可正常播放的獨立 2D 場景。
2. 場景根節點自行實作 `play_pet_animation(animation_name: String, loop: bool)`。在此方法內呼叫你所選 runtime 的實際 API；不同 runtime API 可能不同，轉接器不硬綁某套方法名稱。
3. 可選實作 `set_pet_parameters(parameters: Dictionary)`，收到 `affection`、`stroking`、`celebrating`，用於表情或混合動畫。
4. 建立 `Node3D` 場景，掛上 `scripts/presentation/spine_pet_presentation.gd`。設定其 `spine_scene` 指向上述 2D 場景。
5. 設定 `idle_animation` / `stroke_animation` / `happy_animation` / `greeting_animation`，預設為 `idle` / `pet` / `happy` / `greet`。原點預設在 512×512 畫布的 (256, 440)，依素材調整 `skeleton_origin`、`canvas_size` 和 `world_pixel_size`，避免裁切。
6. 在主場景選取根節點 `LittleDays`，將該外觀場景拖到 Inspector 的 **Pet Presentation Scene** 欄位。它會在建立角色時傳給 `PetActor.presentation_scene`。也可在 `main.gd` 的 `add_child(pet)` **之前**用程式指定：

```gdscript
pet.presentation_scene = preload("res://your_assets/spine_pet.tscn")
```

指定場景的根節點必須繼承 `PetPresentation`；未指定時使用目前的原生外觀。

## 動畫優先序與時間

開心 > 撫摸 > 招呼 > 待機。待機與撫摸循環播放，開心與招呼為一次性動畫。同一狀態不會每幀重新播放。開心結束後，狀態機自動切回目前應有的動畫。

目前由遊戲模擬控制開心長度 `PetState.CELEBRATION_DURATION = 2.2` 秒；請將 Spine 開心動畫製作／調速到這個長度，或在另一次程式變更中統一調整該常數與測試。不要同時從 runtime 的動畫結束事件和遊戲計時器各自重設數值。

## 接入後驗證

- 待機、撫摸、招呼與開心名稱存在，動畫優先序正確。
- 玩家繞行時角色始終面向攝影機，透明背景和尺寸正確。
- 連續撫摸時動畫不會每幀重播。
- 開心動畫結束時只清空快樂度，撫摸度保留。
- 執行 `tests/run_tests.gd`，再以實際 runtime 測試渲染；目前自動測試未驗證任何第三方 Spine runtime。
