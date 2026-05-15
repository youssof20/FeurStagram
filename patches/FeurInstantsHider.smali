.class public Lcom/feurstagram/FeurInstantsHider;
.super Ljava/lang/Object;
.implements Landroid/view/ViewTreeObserver$OnGlobalLayoutListener;

# Persistent global-layout listener that hides Instagram's "Instants" UI in
# the DM inbox (the floating + button + the consumption-preview rounded
# rectangle next to it). Targets two sibling resource ids:
#
#   creation_entrypoint                  - the floating "+" button overlay
#   direct_quick_snap_consumption_preview - the rounded preview backdrop
#
# Both are recycled with the DM fragment, so we stay attached and reapply
# visibility on every layout pass. Toggling the preference back off
# restores both views on the next layout.


# instance fields
.field private mContainer:Landroid/view/ViewGroup;


# direct methods
.method public constructor <init>(Landroid/view/ViewGroup;)V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    iput-object p1, p0, Lcom/feurstagram/FeurInstantsHider;->mContainer:Landroid/view/ViewGroup;
    return-void
.end method


# Resolve resource id by name under the running app's package, falling
# back to "com.instagram.android" for --clone builds where resources.arsc
# still declares the original resource package. Returns 0 if not found.
.method private static resolveId(Landroid/content/Context;Ljava/lang/String;)I
    .locals 5

    invoke-virtual {p0}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v0

    const-string v1, "id"

    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v0, p1, v1, v2}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v3

    if-nez v3, :return

    const-string v2, "com.instagram.android"
    invoke-virtual {v0, p1, v1, v2}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v3

    :return
    return v3
.end method


# Look up `name` and apply the desired visibility to a matching view in the
# window rooted at `root`. Skips silently if the id is unresolved or the
# view is missing.
.method private static applyVisibility(Landroid/view/View;Landroid/content/Context;Ljava/lang/String;I)V
    .locals 3

    invoke-static {p1, p2}, Lcom/feurstagram/FeurInstantsHider;->resolveId(Landroid/content/Context;Ljava/lang/String;)I
    move-result v0
    if-nez v0, :have_id
    return-void

    :have_id
    invoke-virtual {p0, v0}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v1
    if-nez v1, :have_view
    return-void

    :have_view
    invoke-virtual {v1}, Landroid/view/View;->getVisibility()I
    move-result v2
    if-eq v2, p3, :end
    invoke-virtual {v1, p3}, Landroid/view/View;->setVisibility(I)V

    :end
    return-void
.end method


# virtual methods
.method public onGlobalLayout()V
    .locals 5

    iget-object v0, p0, Lcom/feurstagram/FeurInstantsHider;->mContainer:Landroid/view/ViewGroup;
    if-nez v0, :have_container
    return-void

    :have_container
    invoke-virtual {v0}, Landroid/view/ViewGroup;->getContext()Landroid/content/Context;
    move-result-object v1
    if-nez v1, :have_ctx
    return-void

    :have_ctx
    invoke-virtual {v0}, Landroid/view/ViewGroup;->getRootView()Landroid/view/View;
    move-result-object v2
    if-nez v2, :have_root
    return-void

    :have_root
    invoke-static {}, Lcom/feurstagram/FeurConfig;->isInstantsBlocked()Z
    move-result v3

    if-eqz v3, :show_it
    const/16 v4, 0x8
    goto :apply

    :show_it
    const/4 v4, 0x0

    :apply
    const-string v3, "creation_entrypoint"
    invoke-static {v2, v1, v3, v4}, Lcom/feurstagram/FeurInstantsHider;->applyVisibility(Landroid/view/View;Landroid/content/Context;Ljava/lang/String;I)V

    const-string v3, "direct_quick_snap_consumption_preview"
    invoke-static {v2, v1, v3, v4}, Lcom/feurstagram/FeurInstantsHider;->applyVisibility(Landroid/view/View;Landroid/content/Context;Ljava/lang/String;I)V

    return-void
.end method
