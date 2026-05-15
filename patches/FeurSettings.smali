.class public Lcom/feurstagram/FeurSettings;
.super Ljava/lang/Object;

# FeurStagram settings dialog (custom Material 3 dark style, no resources).


.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method


.method public static installHomeTabWatcher(Landroid/view/ViewGroup;)V
    .locals 2

    if-nez p0, :cond_ok
    return-void

    :cond_ok
    const-string v0, "installHomeTabWatcher"
    invoke-static {v0}, Lcom/feurstagram/FeurHooks;->log(Ljava/lang/String;)V

    new-instance v0, Lcom/feurstagram/FeurHomeTabWatcher;
    invoke-direct {v0, p0}, Lcom/feurstagram/FeurHomeTabWatcher;-><init>(Landroid/view/ViewGroup;)V

    invoke-virtual {p0}, Landroid/view/ViewGroup;->getViewTreeObserver()Landroid/view/ViewTreeObserver;
    move-result-object v1
    invoke-virtual {v1, v0}, Landroid/view/ViewTreeObserver;->addOnGlobalLayoutListener(Landroid/view/ViewTreeObserver$OnGlobalLayoutListener;)V

    # Also install the Instants (+ button) hider on the same root - it
    # watches the whole window for the DM inbox's creation_entrypoint view.
    new-instance v0, Lcom/feurstagram/FeurInstantsHider;
    invoke-direct {v0, p0}, Lcom/feurstagram/FeurInstantsHider;-><init>(Landroid/view/ViewGroup;)V

    invoke-virtual {p0}, Landroid/view/ViewGroup;->getViewTreeObserver()Landroid/view/ViewTreeObserver;
    move-result-object v1
    invoke-virtual {v1, v0}, Landroid/view/ViewTreeObserver;->addOnGlobalLayoutListener(Landroid/view/ViewTreeObserver$OnGlobalLayoutListener;)V

    # And the Notes tray hider - watches for the cf_hub_recycler_view that
    # holds the row of friends' note bubbles above the DM thread list.
    new-instance v0, Lcom/feurstagram/FeurNotesHider;
    invoke-direct {v0, p0}, Lcom/feurstagram/FeurNotesHider;-><init>(Landroid/view/ViewGroup;)V

    invoke-virtual {p0}, Landroid/view/ViewGroup;->getViewTreeObserver()Landroid/view/ViewTreeObserver;
    move-result-object v1
    invoke-virtual {v1, v0}, Landroid/view/ViewTreeObserver;->addOnGlobalLayoutListener(Landroid/view/ViewTreeObserver$OnGlobalLayoutListener;)V

    # And the Reels tab hider - hides the clips_tab icon in the bottom
    # tab bar whenever the Reels block is enabled.
    new-instance v0, Lcom/feurstagram/FeurReelsTabHider;
    invoke-direct {v0, p0}, Lcom/feurstagram/FeurReelsTabHider;-><init>(Landroid/view/ViewGroup;)V

    invoke-virtual {p0}, Landroid/view/ViewGroup;->getViewTreeObserver()Landroid/view/ViewTreeObserver;
    move-result-object v1
    invoke-virtual {v1, v0}, Landroid/view/ViewTreeObserver;->addOnGlobalLayoutListener(Landroid/view/ViewTreeObserver$OnGlobalLayoutListener;)V
    return-void
.end method


.method public static attachLongPress(Landroid/view/View;)V
    .locals 1

    if-nez p0, :cond_ok
    return-void

    :cond_ok
    const-string v0, "attachLongPress"
    invoke-static {v0}, Lcom/feurstagram/FeurHooks;->log(Ljava/lang/String;)V
    new-instance v0, Lcom/feurstagram/FeurSettingsLongClick;
    invoke-direct {v0}, Lcom/feurstagram/FeurSettingsLongClick;-><init>()V
    invoke-virtual {p0, v0}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V
    const/4 v0, 0x1
    invoke-virtual {p0, v0}, Landroid/view/View;->setLongClickable(Z)V
    return-void
.end method


.method public static getActivityContext(Landroid/view/View;)Landroid/content/Context;
    .locals 3

    if-nez p0, :cond_ok
    const/4 v0, 0x0
    return-object v0

    :cond_ok
    invoke-virtual {p0}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v0
    move-object v1, v0

    :loop_start
    if-eqz v0, :loop_end
    instance-of v2, v0, Landroid/app/Activity;
    if-nez v2, :loop_end
    instance-of v2, v0, Landroid/content/ContextWrapper;
    if-eqz v2, :loop_end
    check-cast v0, Landroid/content/ContextWrapper;
    invoke-virtual {v0}, Landroid/content/ContextWrapper;->getBaseContext()Landroid/content/Context;
    move-result-object v0
    goto :loop_start

    :loop_end
    if-nez v0, :cond_found
    return-object v1

    :cond_found
    return-object v0
.end method


.method public static show(Landroid/content/Context;)V
    .locals 6

    if-nez p0, :cond_ok
    return-void

    :cond_ok
    :try_start_0
    new-instance v0, Landroid/app/Dialog;
    invoke-direct {v0, p0}, Landroid/app/Dialog;-><init>(Landroid/content/Context;)V

    invoke-static {p0, v0}, Lcom/feurstagram/FeurSettings;->buildContent(Landroid/content/Context;Landroid/app/Dialog;)Landroid/view/View;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/app/Dialog;->setContentView(Landroid/view/View;)V

    const/4 v1, 0x1
    invoke-virtual {v0, v1}, Landroid/app/Dialog;->setCanceledOnTouchOutside(Z)V

    invoke-virtual {v0}, Landroid/app/Dialog;->getWindow()Landroid/view/Window;
    move-result-object v2
    if-eqz v2, :cond_show

    new-instance v3, Landroid/graphics/drawable/ColorDrawable;
    const/4 v4, 0x0
    invoke-direct {v3, v4}, Landroid/graphics/drawable/ColorDrawable;-><init>(I)V
    invoke-virtual {v2, v3}, Landroid/view/Window;->setBackgroundDrawable(Landroid/graphics/drawable/Drawable;)V

    const/4 v3, -0x1
    const/4 v4, -0x2
    invoke-virtual {v2, v3, v4}, Landroid/view/Window;->setLayout(II)V

    const v3, 0x3f19999a    # 0.6f
    invoke-virtual {v2, v3}, Landroid/view/Window;->setDimAmount(F)V

    :cond_show
    invoke-virtual {v0}, Landroid/app/Dialog;->show()V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception v0

    const-string v1, "FeurStagram settings unavailable here"
    const/4 v2, 0x1
    invoke-static {p0, v1, v2}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;
    move-result-object v1
    invoke-virtual {v1}, Landroid/widget/Toast;->show()V
    return-void
.end method


.method private static buildContent(Landroid/content/Context;Landroid/app/Dialog;)Landroid/view/View;
    .locals 14

    invoke-static {}, Lcom/feurstagram/FeurConfig;->isHardcoreMode()Z
    move-result v0

    new-instance v1, Landroid/widget/FrameLayout;
    invoke-direct {v1, p0}, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V

    const/high16 v2, 0x41c00000    # 24.0f
    invoke-static {p0, v2}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v2
    invoke-virtual {v1, v2, v2, v2, v2}, Landroid/widget/FrameLayout;->setPadding(IIII)V

    new-instance v3, Landroid/widget/LinearLayout;
    invoke-direct {v3, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    const/4 v4, 0x1
    invoke-virtual {v3, v4}, Landroid/widget/LinearLayout;->setOrientation(I)V

    const v4, -0xe3e4e1
    const/high16 v5, 0x41e00000    # 28.0f
    invoke-static {v4, v5, p0}, Lcom/feurstagram/FeurSettings;->roundedRect(IFLandroid/content/Context;)Landroid/graphics/drawable/GradientDrawable;
    move-result-object v4
    invoke-virtual {v3, v4}, Landroid/widget/LinearLayout;->setBackground(Landroid/graphics/drawable/Drawable;)V
    invoke-virtual {v3, v2, v2, v2, v2}, Landroid/widget/LinearLayout;->setPadding(IIII)V

    new-instance v4, Landroid/widget/FrameLayout$LayoutParams;
    const/4 v5, -0x1
    const/4 v6, -0x2
    invoke-direct {v4, v5, v6}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V
    invoke-virtual {v1, v3, v4}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    new-instance v4, Landroid/widget/TextView;
    invoke-direct {v4, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    const-string v5, "FeurStagram"
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/4 v5, 0x2
    const/high16 v6, 0x41b00000    # 22.0f
    invoke-virtual {v4, v5, v6}, Landroid/widget/TextView;->setTextSize(IF)V
    const v5, -0x191e1b
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setTextColor(I)V
    const-string v6, "sans-serif-medium"
    const/4 v7, 0x0
    invoke-static {v6, v7}, Landroid/graphics/Typeface;->create(Ljava/lang/String;I)Landroid/graphics/Typeface;
    move-result-object v6
    invoke-virtual {v4, v6}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V
    invoke-virtual {v3, v4}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v4, Landroid/widget/TextView;
    invoke-direct {v4, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    if-eqz v0, :cond_subtitle_normal
    const-string v6, "Permanent lock active - reinstall to unlock."
    goto :cond_subtitle_set

    :cond_subtitle_normal
    const-string v6, "Choose what to hide. Tap Done to clear cache and restart."

    :cond_subtitle_set
    invoke-virtual {v4, v6}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/4 v6, 0x2
    const/high16 v7, 0x41600000    # 14.0f
    invoke-virtual {v4, v6, v7}, Landroid/widget/TextView;->setTextSize(IF)V
    const v6, -0x353b30
    invoke-virtual {v4, v6}, Landroid/widget/TextView;->setTextColor(I)V
    const/high16 v7, 0x40800000    # 4.0f
    invoke-static {p0, v7}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v7
    const/4 v8, 0x0
    invoke-virtual {v4, v8, v7, v8, v8}, Landroid/widget/TextView;->setPadding(IIII)V
    invoke-virtual {v3, v4}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v4, Landroid/widget/TextView;
    invoke-direct {v4, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    const-string v7, "BLOCKED SURFACES"
    invoke-virtual {v4, v7}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/4 v7, 0x2
    const/high16 v8, 0x41400000    # 12.0f
    invoke-virtual {v4, v7, v8}, Landroid/widget/TextView;->setTextSize(IF)V
    invoke-virtual {v4, v6}, Landroid/widget/TextView;->setTextColor(I)V
    const-string v7, "sans-serif-medium"
    const/4 v8, 0x0
    invoke-static {v7, v8}, Landroid/graphics/Typeface;->create(Ljava/lang/String;I)Landroid/graphics/Typeface;
    move-result-object v7
    invoke-virtual {v4, v7}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V
    const/high16 v7, 0x41a00000    # 20.0f
    invoke-static {p0, v7}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v7
    const/high16 v8, 0x41200000    # 10.0f
    invoke-static {p0, v8}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v8
    const/4 v9, 0x0
    invoke-virtual {v4, v9, v7, v9, v8}, Landroid/widget/TextView;->setPadding(IIII)V
    invoke-virtual {v3, v4}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v4, Landroid/widget/LinearLayout;
    invoke-direct {v4, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    const/4 v7, 0x1
    invoke-virtual {v4, v7}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const v7, -0xd4d6d0
    const/high16 v8, 0x41a00000    # 20.0f
    invoke-static {v7, v8, p0}, Lcom/feurstagram/FeurSettings;->roundedRect(IFLandroid/content/Context;)Landroid/graphics/drawable/GradientDrawable;
    move-result-object v7
    invoke-virtual {v4, v7}, Landroid/widget/LinearLayout;->setBackground(Landroid/graphics/drawable/Drawable;)V
    const/high16 v7, 0x40800000    # 4.0f
    invoke-static {p0, v7}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v7
    const/4 v8, 0x0
    invoke-virtual {v4, v8, v7, v8, v7}, Landroid/widget/LinearLayout;->setPadding(IIII)V
    invoke-virtual {v3, v4}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    const-string v7, "Home Feed"
    const-string v8, "block_feed"
    invoke-static {}, Lcom/feurstagram/FeurConfig;->isFeedBlocked()Z
    move-result v9
    invoke-static {p0, v4, v7, v8, v9}, Lcom/feurstagram/FeurSettings;->addRow(Landroid/content/Context;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Z)V

    const-string v7, "Explore"
    const-string v8, "block_explore"
    invoke-static {}, Lcom/feurstagram/FeurConfig;->isExploreBlocked()Z
    move-result v9
    invoke-static {p0, v4, v7, v8, v9}, Lcom/feurstagram/FeurSettings;->addRow(Landroid/content/Context;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Z)V

    const-string v7, "Reels"
    const-string v8, "block_reels"
    invoke-static {}, Lcom/feurstagram/FeurConfig;->isReelsBlocked()Z
    move-result v9
    invoke-static {p0, v4, v7, v8, v9}, Lcom/feurstagram/FeurSettings;->addRow(Landroid/content/Context;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Z)V

    const-string v7, "Stories"
    const-string v8, "block_stories"
    invoke-static {}, Lcom/feurstagram/FeurConfig;->isStoriesBlocked()Z
    move-result v9
    invoke-static {p0, v4, v7, v8, v9}, Lcom/feurstagram/FeurSettings;->addRow(Landroid/content/Context;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Z)V

    const-string v7, "Instants"
    const-string v8, "block_instants"
    invoke-static {}, Lcom/feurstagram/FeurConfig;->isInstantsBlocked()Z
    move-result v9
    invoke-static {p0, v4, v7, v8, v9}, Lcom/feurstagram/FeurSettings;->addRow(Landroid/content/Context;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Z)V

    const-string v7, "Notes"
    const-string v8, "block_notes"
    invoke-static {}, Lcom/feurstagram/FeurConfig;->isNotesBlocked()Z
    move-result v9
    invoke-static {p0, v4, v7, v8, v9}, Lcom/feurstagram/FeurSettings;->addRow(Landroid/content/Context;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Z)V

    new-instance v7, Landroid/widget/LinearLayout;
    invoke-direct {v7, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    const/4 v8, 0x0
    invoke-virtual {v7, v8}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const v8, 0x800005
    invoke-virtual {v7, v8}, Landroid/widget/LinearLayout;->setGravity(I)V

    new-instance v8, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v9, -0x1
    const/4 v10, -0x2
    invoke-direct {v8, v9, v10}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    const/high16 v9, 0x41a00000    # 20.0f
    invoke-static {p0, v9}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v9
    const/4 v10, 0x0
    invoke-virtual {v8, v10, v9, v10, v10}, Landroid/widget/LinearLayout$LayoutParams;->setMargins(IIII)V
    invoke-virtual {v3, v7, v8}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    const-string v10, "Permanent lock"
    const v11, -0xb0c875
    const v12, -0x152201
    const/4 v13, 0x1
    invoke-static {p0, v10, v11, v12, v13}, Lcom/feurstagram/FeurSettings;->makeButton(Landroid/content/Context;Ljava/lang/String;IIZ)Landroid/widget/Button;
    move-result-object v10
    new-instance v11, Lcom/feurstagram/FeurHardcoreButtonClickListener;
    invoke-direct {v11, p0, p1}, Lcom/feurstagram/FeurHardcoreButtonClickListener;-><init>(Landroid/content/Context;Landroid/app/Dialog;)V
    invoke-virtual {v10, v11}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
    if-eqz v0, :cond_perm_enabled
    const/4 v11, 0x0
    invoke-virtual {v10, v11}, Landroid/widget/Button;->setEnabled(Z)V
    const v11, 0x3f19999a    # 0.6f
    invoke-virtual {v10, v11}, Landroid/widget/Button;->setAlpha(F)V

    :cond_perm_enabled
    invoke-virtual {v7, v10}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v11, Landroid/view/View;
    invoke-direct {v11, p0}, Landroid/view/View;-><init>(Landroid/content/Context;)V
    const/high16 v12, 0x41000000    # 8.0f
    invoke-static {p0, v12}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v12
    new-instance v8, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v9, 0x1
    invoke-direct {v8, v12, v9}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    invoke-virtual {v11, v8}, Landroid/view/View;->setLayoutParams(Landroid/view/ViewGroup$LayoutParams;)V
    invoke-virtual {v7, v11}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    const-string v8, "Done"
    const v9, -0x2f4301
    const v11, -0xc8e18d
    const/4 v12, 0x1
    invoke-static {p0, v8, v9, v11, v12}, Lcom/feurstagram/FeurSettings;->makeButton(Landroid/content/Context;Ljava/lang/String;IIZ)Landroid/widget/Button;
    move-result-object v8
    new-instance v9, Lcom/feurstagram/FeurDoneButtonClickListener;
    invoke-direct {v9, p0, p1}, Lcom/feurstagram/FeurDoneButtonClickListener;-><init>(Landroid/content/Context;Landroid/app/Dialog;)V
    invoke-virtual {v8, v9}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
    invoke-virtual {v7, v8}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    return-object v1
.end method


.method private static addRow(Landroid/content/Context;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Z)V
    .locals 11

    const v0, -0xd4d6d0      # surface container
    const v1, -0xc9cbc5      # divider
    const v2, -0x191e1b      # on surface
    const v3, -0x6c7067      # outline
    const v4, -0x2f4301      # primary
    const v5, -0xc8e18d      # on primary
    const v6, -0x353b30      # on surface variant

    new-instance v7, Landroid/widget/LinearLayout;
    invoke-direct {v7, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    const/4 v8, 0x0
    invoke-virtual {v7, v8}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const/16 v8, 0x10
    invoke-virtual {v7, v8}, Landroid/widget/LinearLayout;->setGravity(I)V

    const/high16 v8, 0x41a00000    # 20.0f
    invoke-static {p0, v8}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v8
    const/high16 v9, 0x41600000    # 14.0f
    invoke-static {p0, v9}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v9
    invoke-virtual {v7, v8, v9, v8, v9}, Landroid/widget/LinearLayout;->setPadding(IIII)V

    const/high16 v8, 0x42800000    # 64.0f
    invoke-static {p0, v8}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v8
    invoke-virtual {v7, v8}, Landroid/widget/LinearLayout;->setMinimumHeight(I)V

    const/high16 v8, 0x41800000    # 16.0f
    invoke-static {v0, v8, p0}, Lcom/feurstagram/FeurSettings;->roundedRect(IFLandroid/content/Context;)Landroid/graphics/drawable/GradientDrawable;
    move-result-object v8
    const v9, 0x33ffffff
    invoke-static {v9, v8}, Lcom/feurstagram/FeurSettings;->ripple(ILandroid/graphics/drawable/Drawable;)Landroid/graphics/drawable/Drawable;
    move-result-object v8
    invoke-virtual {v7, v8}, Landroid/widget/LinearLayout;->setBackground(Landroid/graphics/drawable/Drawable;)V

    new-instance v8, Landroid/widget/LinearLayout;
    invoke-direct {v8, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    const/4 v9, 0x1
    invoke-virtual {v8, v9}, Landroid/widget/LinearLayout;->setOrientation(I)V

    new-instance v9, Landroid/widget/TextView;
    invoke-direct {v9, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    invoke-virtual {v9, p2}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/4 v10, 0x2
    const/high16 v0, 0x41800000    # 16.0f
    invoke-virtual {v9, v10, v0}, Landroid/widget/TextView;->setTextSize(IF)V
    invoke-virtual {v9, v2}, Landroid/widget/TextView;->setTextColor(I)V
    const-string v10, "sans-serif-medium"
    const/4 v0, 0x0
    invoke-static {v10, v0}, Landroid/graphics/Typeface;->create(Ljava/lang/String;I)Landroid/graphics/Typeface;
    move-result-object v10
    invoke-virtual {v9, v10}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V
    invoke-virtual {v8, v9}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v9, Landroid/widget/TextView;
    invoke-direct {v9, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    const-string v10, "Hide this surface in Instagram."
    invoke-virtual {v9, v10}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/4 v10, 0x2
    const/high16 v0, 0x41500000    # 13.0f
    invoke-virtual {v9, v10, v0}, Landroid/widget/TextView;->setTextSize(IF)V
    invoke-virtual {v9, v6}, Landroid/widget/TextView;->setTextColor(I)V
    invoke-virtual {v8, v9}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v9, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v10, 0x0
    const/4 v0, -0x2
    const/high16 v6, 0x3f800000    # 1.0f
    invoke-direct {v9, v10, v0, v6}, Landroid/widget/LinearLayout$LayoutParams;-><init>(IIF)V
    invoke-virtual {v7, v8, v9}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    new-instance v8, Landroidx/appcompat/widget/SwitchCompat;
    invoke-direct {v8, p0}, Landroidx/appcompat/widget/SwitchCompat;-><init>(Landroid/content/Context;)V
    invoke-virtual {v8, p4}, Landroidx/appcompat/widget/SwitchCompat;->setChecked(Z)V
    const/4 v9, 0x0
    invoke-virtual {v8, v9}, Landroidx/appcompat/widget/SwitchCompat;->setShowText(Z)V

    new-instance v10, Lcom/feurstagram/FeurSwitchListener;
    invoke-direct {v10, p3}, Lcom/feurstagram/FeurSwitchListener;-><init>(Ljava/lang/String;)V
    invoke-virtual {v8, v10}, Landroidx/appcompat/widget/SwitchCompat;->setOnCheckedChangeListener(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V

    invoke-static {v4, v3}, Lcom/feurstagram/FeurSettings;->buildStateList(II)Landroid/content/res/ColorStateList;
    move-result-object v10
    invoke-virtual {v8, v10}, Landroidx/appcompat/widget/SwitchCompat;->setTrackTintList(Landroid/content/res/ColorStateList;)V

    invoke-static {v5, v3}, Lcom/feurstagram/FeurSettings;->buildStateList(II)Landroid/content/res/ColorStateList;
    move-result-object v10
    invoke-virtual {v8, v10}, Landroidx/appcompat/widget/SwitchCompat;->setThumbTintList(Landroid/content/res/ColorStateList;)V

    invoke-static {}, Lcom/feurstagram/FeurConfig;->isHardcoreMode()Z
    move-result v10
    if-eqz v10, :cond_row_enabled
    const/4 v10, 0x0
    invoke-virtual {v8, v10}, Landroidx/appcompat/widget/SwitchCompat;->setEnabled(Z)V
    const v10, 0x3ec28f5c    # 0.38f
    invoke-virtual {v7, v10}, Landroid/widget/LinearLayout;->setAlpha(F)V
    goto :cond_row_done

    :cond_row_enabled
    const/high16 v10, 0x3f800000    # 1.0f
    invoke-virtual {v7, v10}, Landroid/widget/LinearLayout;->setAlpha(F)V

    :cond_row_done
    invoke-virtual {v7, v8}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v8, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v10, -0x1
    const/4 v0, -0x2
    invoke-direct {v8, v10, v0}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    invoke-virtual {p1, v7, v8}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    invoke-static {p0, v1}, Lcom/feurstagram/FeurSettings;->makeDivider(Landroid/content/Context;I)Landroid/view/View;
    move-result-object v10
    invoke-virtual {p1, v10}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    return-void
.end method


.method public static dp(Landroid/content/Context;F)I
    .locals 2

    invoke-virtual {p0}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v0
    invoke-virtual {v0}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v0
    iget v0, v0, Landroid/util/DisplayMetrics;->density:F
    mul-float/2addr p1, v0
    const/high16 v1, 0x3f000000    # 0.5f
    add-float/2addr p1, v1
    float-to-int v0, p1
    return v0
.end method


.method public static roundedRect(IFLandroid/content/Context;)Landroid/graphics/drawable/GradientDrawable;
    .locals 3

    new-instance v0, Landroid/graphics/drawable/GradientDrawable;
    invoke-direct {v0}, Landroid/graphics/drawable/GradientDrawable;-><init>()V
    invoke-virtual {v0, p0}, Landroid/graphics/drawable/GradientDrawable;->setColor(I)V
    invoke-static {p2, p1}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v1
    int-to-float v2, v1
    invoke-virtual {v0, v2}, Landroid/graphics/drawable/GradientDrawable;->setCornerRadius(F)V
    return-object v0
.end method


.method public static ripple(ILandroid/graphics/drawable/Drawable;)Landroid/graphics/drawable/Drawable;
    .locals 3

    invoke-static {p0}, Landroid/content/res/ColorStateList;->valueOf(I)Landroid/content/res/ColorStateList;
    move-result-object v0
    new-instance v1, Landroid/graphics/drawable/RippleDrawable;
    const/4 v2, 0x0
    invoke-direct {v1, v0, p1, v2}, Landroid/graphics/drawable/RippleDrawable;-><init>(Landroid/content/res/ColorStateList;Landroid/graphics/drawable/Drawable;Landroid/graphics/drawable/Drawable;)V
    return-object v1
.end method


.method public static buildStateList(II)Landroid/content/res/ColorStateList;
    .locals 7

    const/4 v0, 0x2
    new-array v1, v0, [[I

    const/4 v2, 0x1
    new-array v3, v2, [I
    const v4, 0x10100a0
    const/4 v5, 0x0
    aput v4, v3, v5
    aput-object v3, v1, v5

    new-array v3, v5, [I
    aput-object v3, v1, v2

    new-array v0, v0, [I
    aput p0, v0, v5
    aput p1, v0, v2

    new-instance v6, Landroid/content/res/ColorStateList;
    invoke-direct {v6, v1, v0}, Landroid/content/res/ColorStateList;-><init>([[I[I)V
    return-object v6
.end method


.method public static makeButton(Landroid/content/Context;Ljava/lang/String;IIZ)Landroid/widget/Button;
    .locals 7

    new-instance v0, Landroid/widget/Button;
    invoke-direct {v0, p0}, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
    invoke-virtual {v0, p1}, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/widget/Button;->setAllCaps(Z)V
    invoke-virtual {v0, p3}, Landroid/widget/Button;->setTextColor(I)V

    const/4 v2, 0x2
    const/high16 v3, 0x41600000    # 14.0f
    invoke-virtual {v0, v2, v3}, Landroid/widget/Button;->setTextSize(IF)V

    const-string v3, "sans-serif-medium"
    const/4 v4, 0x0
    invoke-static {v3, v4}, Landroid/graphics/Typeface;->create(Ljava/lang/String;I)Landroid/graphics/Typeface;
    move-result-object v3
    invoke-virtual {v0, v3}, Landroid/widget/Button;->setTypeface(Landroid/graphics/Typeface;)V

    const/high16 v3, 0x42200000    # 40.0f
    invoke-static {p0, v3}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v3
    invoke-virtual {v0, v3}, Landroid/widget/Button;->setMinimumHeight(I)V

    const/high16 v3, 0x41c00000    # 24.0f
    invoke-static {p0, v3}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v3
    const/4 v4, 0x0
    invoke-virtual {v0, v3, v4, v3, v4}, Landroid/widget/Button;->setPadding(IIII)V

    const/high16 v3, 0x41a00000    # 20.0f
    invoke-static {p2, v3, p0}, Lcom/feurstagram/FeurSettings;->roundedRect(IFLandroid/content/Context;)Landroid/graphics/drawable/GradientDrawable;
    move-result-object v5
    const v6, 0x33ffffff
    invoke-static {v6, v5}, Lcom/feurstagram/FeurSettings;->ripple(ILandroid/graphics/drawable/Drawable;)Landroid/graphics/drawable/Drawable;
    move-result-object v5
    invoke-virtual {v0, v5}, Landroid/widget/Button;->setBackground(Landroid/graphics/drawable/Drawable;)V

    return-object v0
.end method


.method public static makeDivider(Landroid/content/Context;I)Landroid/view/View;
    .locals 6

    new-instance v0, Landroid/view/View;
    invoke-direct {v0, p0}, Landroid/view/View;-><init>(Landroid/content/Context;)V
    invoke-virtual {v0, p1}, Landroid/view/View;->setBackgroundColor(I)V

    const/high16 v1, 0x3f800000    # 1.0f
    invoke-static {p0, v1}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v1
    new-instance v2, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v3, -0x1
    invoke-direct {v2, v3, v1}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V

    const/high16 v1, 0x41a00000    # 20.0f
    invoke-static {p0, v1}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v1
    const/4 v3, 0x0
    invoke-virtual {v2, v1, v3, v1, v3}, Landroid/widget/LinearLayout$LayoutParams;->setMargins(IIII)V
    invoke-virtual {v0, v2}, Landroid/view/View;->setLayoutParams(Landroid/view/ViewGroup$LayoutParams;)V
    return-object v0
.end method


.method public static makeChip(Landroid/content/Context;Ljava/lang/String;II)Landroid/view/View;
    .locals 6

    new-instance v0, Landroid/widget/TextView;
    invoke-direct {v0, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    invoke-virtual {v0, p1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    invoke-virtual {v0, p3}, Landroid/widget/TextView;->setTextColor(I)V
    const/4 v1, 0x2
    const/high16 v2, 0x41400000    # 12.0f
    invoke-virtual {v0, v1, v2}, Landroid/widget/TextView;->setTextSize(IF)V

    const-string v2, "sans-serif-medium"
    const/4 v3, 0x0
    invoke-static {v2, v3}, Landroid/graphics/Typeface;->create(Ljava/lang/String;I)Landroid/graphics/Typeface;
    move-result-object v2
    invoke-virtual {v0, v2}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V

    const/high16 v2, 0x41400000    # 12.0f
    invoke-static {p0, v2}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v2
    const/high16 v3, 0x40c00000    # 6.0f
    invoke-static {p0, v3}, Lcom/feurstagram/FeurSettings;->dp(Landroid/content/Context;F)I
    move-result v3
    invoke-virtual {v0, v2, v3, v2, v3}, Landroid/widget/TextView;->setPadding(IIII)V

    const/high16 v4, 0x42480000    # 50.0f
    invoke-static {p2, v4, p0}, Lcom/feurstagram/FeurSettings;->roundedRect(IFLandroid/content/Context;)Landroid/graphics/drawable/GradientDrawable;
    move-result-object v4
    invoke-virtual {v0, v4}, Landroid/widget/TextView;->setBackground(Landroid/graphics/drawable/Drawable;)V
    return-object v0
.end method
