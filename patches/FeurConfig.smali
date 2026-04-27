.class public Lcom/feurstagram/FeurConfig;
.super Ljava/lang/Object;

# FeurStagram Configuration
# Backed by SharedPreferences (file: feurstagram_prefs).
# Four independent toggles: feed, explore, reels, stories.
# All four default to true (blocked) on first launch.


.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method


.method public static isHardcoreMode()Z
    .locals 2

    const-string v0, "hardcore_mode"
    const/4 v1, 0x0
    invoke-static {v0, v1}, Lcom/feurstagram/FeurConfig;->getBlocked(Ljava/lang/String;Z)Z
    move-result v0
    return v0
.end method


.method public static enableHardcoreMode()V
    .locals 4

    invoke-static {}, Lcom/feurstagram/FeurConfig;->getAppContext()Landroid/content/Context;
    move-result-object v0

    if-nez v0, :cond_has_ctx
    return-void

    :cond_has_ctx
    const-string v1, "feurstagram_prefs"
    const/4 v2, 0x0
    invoke-virtual {v0, v1, v2}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v0

    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v0

    const-string v1, "hardcore_mode"
    const/4 v2, 0x1
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;
    move-result-object v0

    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V
    return-void
.end method


# Retrieve the process Application context via reflection on ActivityThread.
# Returns null if we cannot resolve it.
.method public static getAppContext()Landroid/content/Context;
    .locals 4

    :try_start_0
    const-string v0, "android.app.ActivityThread"
    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;
    move-result-object v0

    const-string v1, "currentApplication"
    const/4 v2, 0x0
    new-array v2, v2, [Ljava/lang/Class;
    invoke-virtual {v0, v1, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;
    move-result-object v0

    const/4 v1, 0x0
    const/4 v2, 0x0
    new-array v2, v2, [Ljava/lang/Object;
    invoke-virtual {v0, v1, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v0

    check-cast v0, Landroid/content/Context;

    # Clone-mode bootstrap: register notification channels on first resolution
    # of the app Context. Idempotent (guarded by a static flag inside).
    invoke-static {v0}, Lcom/feurstagram/FeurNotificationChannels;->ensureCreated(Landroid/content/Context;)V

    return-object v0
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    :catch_0
    move-exception v0
    const/4 v1, 0x0
    return-object v1
.end method


# getBlocked(String key, boolean defaultValue) -> boolean
.method public static getBlocked(Ljava/lang/String;Z)Z
    .locals 3

    invoke-static {}, Lcom/feurstagram/FeurConfig;->getAppContext()Landroid/content/Context;
    move-result-object v0

    if-nez v0, :cond_has_ctx
    return p1

    :cond_has_ctx
    const-string v1, "feurstagram_prefs"
    const/4 v2, 0x0
    invoke-virtual {v0, v1, v2}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v0

    invoke-interface {v0, p0, p1}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z
    move-result v0
    return v0
.end method


# setBlocked(String key, boolean value)
.method public static setBlocked(Ljava/lang/String;Z)V
    .locals 3

    # Hardcore lock: freeze any block_* toggle at its current value.
    invoke-static {}, Lcom/feurstagram/FeurConfig;->isHardcoreMode()Z
    move-result v0
    if-eqz v0, :guard_done
    if-eqz p0, :guard_done

    const-string v1, "block_"
    invoke-virtual {p0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v2
    if-eqz v2, :guard_done
    return-void

    :guard_done

    invoke-static {}, Lcom/feurstagram/FeurConfig;->getAppContext()Landroid/content/Context;
    move-result-object v0

    if-nez v0, :cond_has_ctx
    return-void

    :cond_has_ctx
    const-string v1, "feurstagram_prefs"
    const/4 v2, 0x0
    invoke-virtual {v0, v1, v2}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v0

    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v0

    invoke-interface {v0, p0, p1}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;
    move-result-object v0

    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V
    return-void
.end method


.method public static isFeedBlocked()Z
    .locals 2

    const-string v0, "block_feed"
    const/4 v1, 0x1
    invoke-static {v0, v1}, Lcom/feurstagram/FeurConfig;->getBlocked(Ljava/lang/String;Z)Z
    move-result v0
    return v0
.end method


.method public static isExploreBlocked()Z
    .locals 2

    const-string v0, "block_explore"
    const/4 v1, 0x1
    invoke-static {v0, v1}, Lcom/feurstagram/FeurConfig;->getBlocked(Ljava/lang/String;Z)Z
    move-result v0
    return v0
.end method


.method public static isReelsBlocked()Z
    .locals 2

    const-string v0, "block_reels"
    const/4 v1, 0x1
    invoke-static {v0, v1}, Lcom/feurstagram/FeurConfig;->getBlocked(Ljava/lang/String;Z)Z
    move-result v0
    return v0
.end method


.method public static isStoriesBlocked()Z
    .locals 2

    const-string v0, "block_stories"
    const/4 v1, 0x0
    invoke-static {v0, v1}, Lcom/feurstagram/FeurConfig;->getBlocked(Ljava/lang/String;Z)Z
    move-result v0
    return v0
.end method
