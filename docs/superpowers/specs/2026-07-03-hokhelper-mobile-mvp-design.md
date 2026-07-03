# HOK Helper Mobile MVP 1.0 Design

## Purpose

HOK Helper Mobile is the Android-first mobile app version of the existing `hokx` portal. The app should eventually cover nearly every page and capability from the web portal, including login, hero data, content browsing, tools, community, and profile features. MVP 1.0 focuses on building a polished native app foundation and migrating the core portal experience first.

The app will live in this repository, `/Users/nourhr/dev/pycharm/projects/hokhelper-mobi`, as an independent Flutter project. It will call the existing Django backend in `/Users/nourhr/dev/pycharm/projects/okhok/hok` through the existing `/hokx/` REST API surface.

## Scope

### MVP 1.0 Includes

- Android-first Flutter app scaffold.
- App shell with native bottom navigation.
- API client for Django `/hokx/` endpoints.
- JWT login session handling.
- Region, language, and theme state.
- Home page aggregation.
- Hero gallery and hero detail.
- Skin and CG browsing.
- Build scheme browsing.
- Tier list and ranking browsing.
- Global search.
- Email login, registration, and password reset through existing backend email APIs.
- User profile and settings.
- Mobile-first visual design system for all MVP screens.

### MVP 1.0 Excludes

- BP simulator editing.
- BuildSim full editor.
- TierList full editor.
- AI prompt image generation.
- Community post creation and comments.
- Push notifications.
- Offline-first sync.
- iOS build pipeline.
- App store release automation.

These excluded features are reserved for later phases after the foundation is stable.

## Product Direction

The product should feel like a real gaming assistant app, not a web page inside a shell. Flutter is selected because it can produce a more unified, polished, animation-rich Android experience while keeping a clear path to iOS later.

The design should use a premium dark game aesthetic with restrained highlights. It should rely on actual HOK hero, skin, CG, and content imagery as primary visual material. UI chrome should stay quiet enough that players can scan hero data, build information, rankings, and content without decorative clutter.

## Navigation

MVP 1.0 uses five primary tabs:

1. Home
   - Aggregated portal entry.
   - Featured heroes, tier highlights, new content, recommended builds, and quick actions.

2. Heroes
   - Hero gallery.
   - Hero detail pages with stats, skills, relationships, history, and builds where backend data is available.

3. Content
   - Skins.
   - CG.
   - Topic article list and detail.
   - Esports and leaks are deferred to Version 1.1.

4. Tools
   - MVP read-only tools and rankings.
   - Build scheme explorer.
   - Tier list and leaderboard views.
   - Locked preview entries for BP simulator, BuildSim, team builder, and AI tools only if needed for navigation continuity.

5. Me
   - Login and registration entry.
   - Profile.
   - Growth/points summary if available.
   - Settings for language, region, and theme.
   - Logout.

## Architecture

The Flutter app should use a layered architecture:

```text
Screens and widgets
  -> Feature controllers/state
  -> Repositories
  -> API client
  -> Django /hokx REST API
```

### App Layer

The app layer owns startup, routing, tab navigation, global overlays, theme, and localization bootstrap. It should use Riverpod for app-wide state, with providers for auth, locale, region, and theme.

### Feature Layer

Each feature should be grouped by product domain:

- `home`
- `auth`
- `heroes`
- `content`
- `builds`
- `rankings`
- `search`
- `profile`
- `settings`

Each feature owns its screens, widgets, repository, state/controller, and models when those models are feature-specific.

### Core Layer

The core layer owns cross-feature infrastructure:

- HTTP client.
- API response parsing.
- Auth token storage.
- Error mapping.
- Region and language helpers.
- Image loading and cache policy.
- Shared widgets.
- Design tokens.

## Backend Integration

The app calls the existing Django `/hokx/` API. It should not duplicate backend business logic in the mobile client.

Important existing endpoint groups:

- `auth/email/*`
- `auth/google/*`
- `auth/discord/*`
- `user/profile/*`
- `user/growth`
- `hero/all`
- `hero/gallery`
- `hero/{hero_id}`
- `hero/{hero_id}/stats`
- `hero/{hero_id}/skills`
- `hero/{hero_id}/history`
- `hero/relationships`
- `skin/list`
- `skin/{skin_id}`
- `cg/list`
- `cg/{cg_id}`
- `build/schemes`
- `build/equips`
- `build/runes`
- `build/summoner-skills`
- `teambuild/recommend`
- `ranking/heroes`
- `ranking/players`
- `ranking/equips`
- `ranking/tier-list`
- `search/global`
- `home/stats`
- `topic/articles`
- `topic/article`

The mobile app should preserve the backend response shape:

```json
{
  "success": true,
  "message": "Success message",
  "result": {}
}
```

List requests should keep the existing filtering shape:

```json
{
  "page": 1,
  "pageSize": 10,
  "sort": "heroName",
  "order": "asc",
  "filterRules": [
    { "field": "region_id", "op": "eq", "value": 2 }
  ]
}
```

## Authentication

MVP 1.0 should support email login through the existing backend APIs. Email registration and password reset should be implemented through the existing email verification endpoints. If the backend reports that Turnstile captcha is enabled, the mobile app should open the captcha step in an in-app web challenge before requesting the verification code.

Google and Discord login are deferred to Version 1.1 because mobile redirect handling requires Android intent filters and provider callback configuration.

JWT behavior:

- Store access and refresh tokens in secure storage.
- Attach `Authorization: Bearer <access>` to authenticated requests.
- Clear token and user state on 401 or 403.
- Return the user to the Me tab login state after session expiry.

Password reset should be exposed through the email verification flow and should use the same captcha handling as registration.

## Region and Language

The app must keep the existing multi-region model:

- Region 1: China.
- Region 2: English.
- Region 3: Indonesia.

Every region-separated request should include `region_id` through request body filter rules, query parameters, or endpoint-specific parameters matching the existing web API behavior.

The app should support English, Chinese, and Indonesian. Language can default from device locale and be changed in Settings. The selected language should also determine the default backend region unless the user explicitly chooses another region.

## Visual System

MVP 1.0 should use a native mobile design system rather than copying web layouts directly.

Design direction:

- Dark game-oriented base.
- Gold and cyan accents.
- Strong image-first hero and skin surfaces.
- Compact data cards for rankings and stats.
- Bottom sheets for filters and actions.
- Skeleton loading states for image-heavy lists.
- Native-feeling page transitions and tab behavior.

Accessibility and usability requirements:

- Touch targets at least 44 px.
- Body text equivalent to at least 16 px where dense data does not require smaller labels.
- Clear loading, empty, and error states.
- Text must not overlap images or controls on common Android screen sizes.
- Avoid relying only on color to communicate state.

## Error Handling

The API client should classify errors into:

- Network unavailable.
- Backend unavailable.
- Authentication expired.
- Permission denied.
- Validation or business error.
- Unknown error.

Screens should show recoverable states with retry actions. Auth expiration should clear session state and show a login prompt without crashing the current app shell.

## Performance

MVP 1.0 should be optimized for image-heavy browsing:

- Use cached network images.
- Reserve layout space for images to avoid jumps.
- Paginate long lists.
- Avoid loading full hero detail bundles in list screens.
- Use pull-to-refresh and incremental loading where lists are large.

## Testing and Verification

MVP 1.0 is complete when:

- Android debug build installs and launches.
- API base URL can be configured per environment.
- Email login works against the Django backend.
- Authenticated requests attach JWT.
- Session expiry clears user state.
- Region and language can be changed and persist across restarts.
- Home, hero gallery, hero detail, skin/CG browsing, build scheme browsing, rankings, search, profile, and settings screens render real backend data.
- Empty, loading, and error states are visible and recoverable.
- The app works on common Android phone viewport sizes without layout overflow.

## Later Phases

### Version 1.1

- Community post browsing.
- Post detail.
- Comments.
- Likes and favorites.
- Notifications.
- Following and followers.
- Activity assistance.
- Esports and leaks if not included in MVP content.

### Version 1.2

- BP simulator.
- BuildSim editor.
- TierList editor.
- Team builder.
- Prompt library and AI image generation.
- Curiosity lab.

### Version 1.3

- Push notifications.
- Offline cache.
- Deep links.
- Android release signing.
- App update prompts.
- iOS preparation.

## Decisions

- MVP 1.0 uses Flutter with Riverpod for state management.
- MVP 1.0 prioritizes email authentication. Google and Discord OAuth move to Version 1.1.
- MVP 1.0 includes topic articles in the Content tab. Esports and leaks move to Version 1.1.
