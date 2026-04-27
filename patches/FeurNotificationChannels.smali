.class public Lcom/feurstagram/FeurNotificationChannels;
.super Ljava/lang/Object;

# FeurStagram clone-mode notification channels bootstrap.
#
# When the package is renamed (com.instagram.android -> clone), Instagram's
# usual channel-registration path doesn't run for the cloned package, so any
# incoming push referencing e.g. "ig_direct" is dropped by the system with
# "No Channel found for pkg=...". We mirror Instagram's registration here by
# enumerating LX/9a2.values() (Instagram's NotificationChannelDef enum) and
# calling NotificationManager.createNotificationChannel for each entry that
# isn't already known to the system.
#
# Idempotent (createNotificationChannel is a no-op if the channel exists with
# the same id), and gated on a static flag so the loop runs at most once per
# process.


# Static guard so we only register channels once per process.
.field private static sInitialized:Z = false


.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method


# ensureCreated(Context) - idempotent. Called from FeurConfig.getAppContext().
.method public static ensureCreated(Landroid/content/Context;)V
    .locals 9

    if-nez p0, :have_ctx
    return-void

    :have_ctx
    sget-boolean v0, Lcom/feurstagram/FeurNotificationChannels;->sInitialized:Z
    if-eqz v0, :do_init
    return-void

    :do_init
    const/4 v0, 0x1
    sput-boolean v0, Lcom/feurstagram/FeurNotificationChannels;->sInitialized:Z

    :try_start_main
    # Android 8+ check: NotificationChannel exists from API 26 onward.
    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I
    const/16 v1, 0x1a
    if-ge v0, v1, :api_ok
    return-void

    :api_ok
    const-string v0, "notification"
    invoke-virtual {p0, v0}, Landroid/content/Context;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v0
    check-cast v0, Landroid/app/NotificationManager;

    if-nez v0, :have_nm
    return-void

    :have_nm
    # Clone-only safety net. On a non-cloned build (package == com.instagram.android)
    # Instagram registers its channels via its own init path with proper group,
    # lights, vibration etc. — registering them ourselves would clobber that with
    # a barebones channel. Bail out for non-clone packages so the patch is safe
    # to ship in both build modes.
    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;
    move-result-object v2
    const-string v3, "com.instagram.android"
    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :is_clone
    return-void

    :is_clone
    invoke-static {}, LX/9a2;->values()[LX/9a2;
    move-result-object v1

    array-length v2, v1
    const/4 v3, 0x0

    :loop_top
    if-ge v3, v2, :loop_done
    aget-object v4, v1, v3

    :try_start_one
    iget-object v5, v4, LX/9a2;->A01:Ljava/lang/String;
    iget v6, v4, LX/9a2;->A00:I

    if-eqz v5, :skip_one

    invoke-virtual {v0, v5}, Landroid/app/NotificationManager;->getNotificationChannel(Ljava/lang/String;)Landroid/app/NotificationChannel;
    move-result-object v7
    if-nez v7, :skip_one

    # Use the enum constant name (e.g. "IG_DIRECT") as the user-visible label.
    # Instagram's own UI replaces this with a localized string when available;
    # this is a safe fallback so the channel exists at all.
    invoke-virtual {v4}, Ljava/lang/Enum;->name()Ljava/lang/String;
    move-result-object v7

    new-instance v8, Landroid/app/NotificationChannel;
    invoke-direct {v8, v5, v7, v6}, Landroid/app/NotificationChannel;-><init>(Ljava/lang/String;Ljava/lang/CharSequence;I)V

    invoke-virtual {v0, v8}, Landroid/app/NotificationManager;->createNotificationChannel(Landroid/app/NotificationChannel;)V
    :try_end_one
    .catch Ljava/lang/Throwable; {:try_start_one .. :try_end_one} :catch_one

    goto :skip_one

    :catch_one
    move-exception v7

    :skip_one
    add-int/lit8 v3, v3, 0x1
    goto :loop_top

    :loop_done
    :try_end_main
    .catch Ljava/lang/Throwable; {:try_start_main .. :try_end_main} :catch_main

    return-void

    :catch_main
    move-exception v0
    return-void
.end method
