.class public Lcom/feurstagram/FeurReelsSwipeCallback;
.super LX/08wI;

# OnPageChangeCallback for Instagram's main bottom-tab ViewPager2 that
# bounces the user past the Reels page whenever the Reels block is on.
# Hiding clips_tab in the bottom bar only removes the icon; the underlying
# ViewPager2 still has the Reels page in its adapter, so swiping right
# from Home would otherwise land you straight on Reels.
#
# Strategy: track the last selected page, and when the next selection
# lands on Reels, immediately call setCurrentItem(targetIndex, false) in
# the same direction (skip forward on a left-to-right swipe, backward on
# a right-to-left swipe). Falls back to forward when direction can't be
# inferred (e.g. fresh process start landing on Reels).
#
# Obfuscation map for this Instagram build (429.1.0.44.70):
#   LX/08wI                                    = androidx.viewpager2.widget.ViewPager2$OnPageChangeCallback
#   LX/08wI->A01(I)V                           = onPageScrollStateChanged(int)
#   LX/08wI->A02(I)V                           = onPageSelected(int)        <- overridden
#   LX/08wI->A03(IFI)V                         = onPageScrolled(int, float, int)
#   ViewPager2->A06(IZ)V                       = setCurrentItem(int, boolean smoothScroll)
#   ViewPager2->A08(LX/08wI;)V                 = registerOnPageChangeCallback(callback)
#   ViewPager2->getAdapter()LX/0EiL;           = RecyclerView.Adapter (obfuscated return type)
#   LX/0EiL->getItemCount()I                   = adapter item count


# instance fields
.field private mPager:Landroidx/viewpager2/widget/ViewPager2;
.field private mReelsIndex:I
.field private mLastPosition:I


# direct methods
.method public constructor <init>(Landroidx/viewpager2/widget/ViewPager2;I)V
    .locals 1
    # Parent LX/08wI has no explicit <init>; chain through Object to match
    # the pattern dex2smali uses for other subclasses of LX/08wI.
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    iput-object p1, p0, Lcom/feurstagram/FeurReelsSwipeCallback;->mPager:Landroidx/viewpager2/widget/ViewPager2;
    iput p2, p0, Lcom/feurstagram/FeurReelsSwipeCallback;->mReelsIndex:I
    const/4 v0, -0x1
    iput v0, p0, Lcom/feurstagram/FeurReelsSwipeCallback;->mLastPosition:I
    return-void
.end method


# Resolve resource id by name under the running app's package, falling
# back to "com.instagram.android" for --clone builds.
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


# Recursive search for a ViewPager2 anywhere under `root`.
.method private static findViewPager2(Landroid/view/View;)Landroidx/viewpager2/widget/ViewPager2;
    .locals 4

    if-nez p0, :have_view
    const/4 v0, 0x0
    return-object v0

    :have_view
    instance-of v0, p0, Landroidx/viewpager2/widget/ViewPager2;
    if-eqz v0, :not_pager
    check-cast p0, Landroidx/viewpager2/widget/ViewPager2;
    return-object p0

    :not_pager
    instance-of v0, p0, Landroid/view/ViewGroup;
    if-nez v0, :is_group
    const/4 v0, 0x0
    return-object v0

    :is_group
    check-cast p0, Landroid/view/ViewGroup;
    invoke-virtual {p0}, Landroid/view/ViewGroup;->getChildCount()I
    move-result v1
    const/4 v2, 0x0

    :loop
    if-lt v2, v1, :loop_body
    const/4 v0, 0x0
    return-object v0

    :loop_body
    invoke-virtual {p0, v2}, Landroid/view/ViewGroup;->getChildAt(I)Landroid/view/View;
    move-result-object v3
    invoke-static {v3}, Lcom/feurstagram/FeurReelsSwipeCallback;->findViewPager2(Landroid/view/View;)Landroidx/viewpager2/widget/ViewPager2;
    move-result-object v3
    if-eqz v3, :next
    return-object v3

    :next
    add-int/lit8 v2, v2, 0x1
    goto :loop
.end method


# Find which direct child of `tabBar` contains the clips_tab view. The
# bottom tab bar's children are in left-to-right page order, so this
# child index matches the Reels page index in the ViewPager2 adapter.
.method private static findReelsIndex(Landroid/view/ViewGroup;)I
    .locals 6

    invoke-virtual {p0}, Landroid/view/ViewGroup;->getContext()Landroid/content/Context;
    move-result-object v0
    if-nez v0, :have_ctx
    const/4 v0, -0x1
    return v0

    :have_ctx
    const-string v1, "clips_tab"
    invoke-static {v0, v1}, Lcom/feurstagram/FeurReelsSwipeCallback;->resolveId(Landroid/content/Context;Ljava/lang/String;)I
    move-result v1
    if-nez v1, :have_id
    const/4 v0, -0x1
    return v0

    :have_id
    invoke-virtual {p0}, Landroid/view/ViewGroup;->getChildCount()I
    move-result v2
    const/4 v3, 0x0

    :loop
    if-lt v3, v2, :loop_body
    const/4 v0, -0x1
    return v0

    :loop_body
    invoke-virtual {p0, v3}, Landroid/view/ViewGroup;->getChildAt(I)Landroid/view/View;
    move-result-object v4
    if-nez v4, :have_child
    add-int/lit8 v3, v3, 0x1
    goto :loop

    :have_child
    invoke-virtual {v4, v1}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v5
    if-eqz v5, :next
    return v3

    :next
    add-int/lit8 v3, v3, 0x1
    goto :loop
.end method


# Try to attach the skip-Reels callback. Returns true on success (so the
# caller can stop retrying), false if the ViewPager2 or clips_tab isn't
# laid out yet. Safe to call repeatedly until it returns true.
.method public static tryInstall(Landroid/view/ViewGroup;)Z
    .locals 4

    if-nez p0, :have_root
    const/4 v0, 0x0
    return v0

    :have_root
    # Walk from the window root so we find the ViewPager2 sibling above
    # the tab bar (the bar itself is below the pager in the view tree).
    invoke-virtual {p0}, Landroid/view/ViewGroup;->getRootView()Landroid/view/View;
    move-result-object v0
    if-nez v0, :have_window
    const/4 v0, 0x0
    return v0

    :have_window
    invoke-static {v0}, Lcom/feurstagram/FeurReelsSwipeCallback;->findViewPager2(Landroid/view/View;)Landroidx/viewpager2/widget/ViewPager2;
    move-result-object v1
    if-nez v1, :have_pager
    const/4 v0, 0x0
    return v0

    :have_pager
    invoke-static {p0}, Lcom/feurstagram/FeurReelsSwipeCallback;->findReelsIndex(Landroid/view/ViewGroup;)I
    move-result v2
    if-gez v2, :have_idx
    const/4 v0, 0x0
    return v0

    :have_idx
    new-instance v3, Lcom/feurstagram/FeurReelsSwipeCallback;
    invoke-direct {v3, v1, v2}, Lcom/feurstagram/FeurReelsSwipeCallback;-><init>(Landroidx/viewpager2/widget/ViewPager2;I)V
    invoke-virtual {v1, v3}, Landroidx/viewpager2/widget/ViewPager2;->A08(LX/08wI;)V

    const-string v0, "FeurReelsSwipeCallback installed"
    invoke-static {v0}, Lcom/feurstagram/FeurHooks;->log(Ljava/lang/String;)V

    const/4 v0, 0x1
    return v0
.end method


# virtual methods

# Override onPageSelected. If Reels is blocked and the new page is the
# Reels page, bounce past it in whichever direction the user came from.
.method public A02(I)V
    .locals 5

    invoke-static {}, Lcom/feurstagram/FeurConfig;->isReelsBlocked()Z
    move-result v0
    if-eqz v0, :store_and_return

    iget v1, p0, Lcom/feurstagram/FeurReelsSwipeCallback;->mReelsIndex:I
    if-eq p1, v1, :redirect
    goto :store_and_return

    :redirect
    iget v2, p0, Lcom/feurstagram/FeurReelsSwipeCallback;->mLastPosition:I

    # Direction: if we came from a lower page, continue forward (+1);
    # if from a higher page, continue backward (-1); else default forward.
    if-ge v2, p1, :try_backward
    add-int/lit8 v3, p1, 0x1
    goto :clamp

    :try_backward
    if-le v2, p1, :default_forward
    add-int/lit8 v3, p1, -0x1
    goto :clamp

    :default_forward
    add-int/lit8 v3, p1, 0x1

    :clamp
    # Clamp lower bound.
    if-gez v3, :check_upper
    const/4 v3, 0x0
    goto :do_set

    :check_upper
    iget-object v4, p0, Lcom/feurstagram/FeurReelsSwipeCallback;->mPager:Landroidx/viewpager2/widget/ViewPager2;
    invoke-virtual {v4}, Landroidx/viewpager2/widget/ViewPager2;->getAdapter()LX/0EiL;
    move-result-object v4
    if-eqz v4, :do_set
    invoke-virtual {v4}, LX/0EiL;->getItemCount()I
    move-result v4
    if-lt v3, v4, :do_set
    add-int/lit8 v3, v4, -0x1

    :do_set
    # No-op guard: if we somehow landed on Reels but the only viable target
    # is Reels itself, give up and just store the position.
    if-ne v3, p1, :go
    goto :store_and_return

    :go
    iget-object v4, p0, Lcom/feurstagram/FeurReelsSwipeCallback;->mPager:Landroidx/viewpager2/widget/ViewPager2;
    # smoothScroll=true: let ViewPager2 animate Reels -> target so the bounce
    # reads as a continuation of the user's swipe instead of a hard cut.
    const/4 v0, 0x1
    invoke-virtual {v4, v3, v0}, Landroidx/viewpager2/widget/ViewPager2;->A06(IZ)V
    # The recursive A02 fired by A06 will update mLastPosition on its
    # store_and_return branch; we don't touch it here.
    return-void

    :store_and_return
    iput p1, p0, Lcom/feurstagram/FeurReelsSwipeCallback;->mLastPosition:I
    return-void
.end method
