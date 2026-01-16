# HomeTrack Technical Architecture

**Version 1.0 | January 2026**

---

## Executive Summary

This document outlines the technical architecture for HomeTrack, a comprehensive home management platform. The architecture is designed to scale from MVP through 1M+ users while maintaining cost efficiency and enabling smooth migrations between infrastructure tiers.

---

## Core Technology Stack

### Frontend

| Platform | Technology | Rationale |
|----------|------------|-----------|
| **Mobile (iOS & Android)** | Flutter | Single codebase, excellent performance, strong ecosystem |
| **Web** | Next.js (React) | Separate codebase for web-optimized UX, SEO support, server-side rendering |

**Key Decision:** Mobile and web share the same backend API but have independent frontends. This allows the web version to have a different, desktop-optimized experience rather than being a carbon copy of the mobile app.

### Backend

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **Database** | Supabase (PostgreSQL) | Managed PostgreSQL, built-in auth, real-time subscriptions, easy migration path |
| **Authentication** | Supabase Auth | Integrated with database, supports OAuth providers, RLS integration |
| **Serverless Functions** | Supabase Edge Functions | Handle external API calls, webhooks, complex operations |
| **Real-time** | Supabase Realtime | Cross-device sync for document and property updates |

### Third-Party Services

| Service | Provider | Purpose |
|---------|----------|---------|
| **Payments** | RevenueCat + Stripe | RevenueCat manages App Store/Play Store subscriptions; Stripe handles web payments; single source of truth across platforms |
| **Analytics** | PostHog | Product analytics, feature flags, session replay, A/B testing |
| **Push Notifications** | Firebase Cloud Messaging | Cross-platform push notifications for maintenance reminders and alerts |
| **Email** | Resend or SendGrid | Transactional emails, expiration reminders, account notifications |
| **Error Tracking** | Sentry | Crash reporting, error monitoring, performance tracking |
| **OCR Processing** | Google Cloud Vision | Document text extraction for search functionality |
| **Property Data** | ATTOM API | Home valuation estimates, property information |
| **Weather Data** | OpenWeatherMap or Tomorrow.io | Weather-triggered maintenance alerts |

---

## Architecture by Scale

### Phase 1: MVP (0–10,000 Users)

**Focus:** Ship fast, validate product-market fit, minimize complexity

```
┌─────────────────────────────────────────────────────────────┐
│                        FRONTEND                              │
│         Flutter (Mobile) + Next.js (Web)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        SUPABASE                              │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐ │
│  │    Auth     │  Database   │   Storage   │  Edge Fns   │ │
│  │             │ (PostgreSQL)│  (100GB)    │             │ │
│  └─────────────┴─────────────┴─────────────┴─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│ RevenueCat  │       │   PostHog   │       │   Sentry    │
│  + Stripe   │       │  Analytics  │       │   Errors    │
└─────────────┘       └─────────────┘       └─────────────┘
```

**Infrastructure Costs:** $100–500/month

| Component | Service | Estimated Cost |
|-----------|---------|----------------|
| Backend | Supabase Pro | $25/month |
| Payments | RevenueCat | Free tier |
| Analytics | PostHog | Free tier |
| Push Notifications | Firebase | Free tier |
| Email | Resend | Free tier → $20/month |
| Error Tracking | Sentry | Free tier |
| OCR | Google Cloud Vision | ~$50/month |
| Property Data | ATTOM API | ~$500/month |

**Key Decisions:**
- Use Supabase Storage for documents (included in Pro plan)
- All services on managed/serverless tiers
- No dedicated infrastructure to manage

---

### Phase 2: Growth (10,000–100,000 Users)

**Focus:** Optimize costs, improve performance, prepare for scale

```
┌─────────────────────────────────────────────────────────────┐
│                        FRONTEND                              │
│         Flutter (Mobile) + Next.js (Web)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        SUPABASE                              │
│  ┌─────────────┬─────────────┬─────────────────────────────┐│
│  │    Auth     │  Database   │       Edge Functions        ││
│  │             │ (PostgreSQL)│   (OCR, webhooks, APIs)     ││
│  └─────────────┴─────────────┴─────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│    Cloudflare R2        │     │         Redis           │
│   (Document Storage)    │     │    (Upstash/managed)    │
│    + CDN (automatic)    │     │       (Caching)         │
└─────────────────────────┘     └─────────────────────────┘
```

**Infrastructure Costs:** $500–3,000/month

| Component | Service | Estimated Cost |
|-----------|---------|----------------|
| Backend | Supabase Pro/Team | $25–599/month |
| Storage | Cloudflare R2 | $50–200/month |
| Caching | Upstash Redis | $10–50/month |
| Payments | RevenueCat | $0–100/month |
| Analytics | PostHog | $0–450/month |
| Push Notifications | Firebase | Free–$50/month |
| Email | Resend/SendGrid | $20–100/month |
| Error Tracking | Sentry | $26–80/month |
| OCR | Google Cloud Vision | $100–500/month |
| Property Data | ATTOM API | $500–1,500/month |

**Key Changes from Phase 1:**
- Migrate document storage from Supabase to Cloudflare R2 (zero egress fees)
- Add Redis caching for frequently accessed data (user profiles, home data, maintenance schedules)
- Separate heavy operations (OCR, reports) into async Edge Functions
- Implement database connection pooling

**Migration Triggers:**
- Supabase Storage exceeds 100GB
- Egress costs becoming significant
- API response times exceeding 500ms
- Need for caching layer

---

### Phase 3: Scale (100,000–1,000,000+ Users)

**Focus:** High availability, cost optimization, performance at scale

```
┌─────────────────────────────────────────────────────────────┐
│                     GLOBAL CDN LAYER                         │
│                 Cloudflare (assets + R2)                     │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                        FRONTEND                              │
│         Flutter (Mobile) + Next.js on Vercel (Web)          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      AWS INFRASTRUCTURE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  API LAYER (ECS/Lambda)              │   │
│  │          Auto-scaling container services             │   │
│  └─────────────────────────────────────────────────────┘   │
│                              │                               │
│       ┌──────────────────────┼──────────────────────┐       │
│       ▼                      ▼                      ▼       │
│  ┌──────────┐          ┌──────────┐          ┌──────────┐  │
│  │   OCR    │          │  Notif.  │          │  Report  │  │
│  │ Service  │          │ Service  │          │ Service  │  │
│  │ (Lambda) │          │  (SQS)   │          │ (Lambda) │  │
│  └──────────┘          └──────────┘          └──────────┘  │
│                              │                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    DATA LAYER                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │   │
│  │  │ PostgreSQL  │  │    Redis    │  │ Elasticsearch│  │   │
│  │  │   (RDS)     │  │(ElastiCache)│  │  (Search)   │  │   │
│  │  │ + Replicas  │  │             │  │             │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│    Cloudflare R2        │     │    Backblaze B2         │
│    (Hot Storage)        │     │   (Cold/Archive)        │
│    Active documents     │     │   Old documents         │
└─────────────────────────┘     └─────────────────────────┘
```

**Infrastructure Costs:** $5,000–50,000+/month

| Component | Service | Estimated Cost |
|-----------|---------|----------------|
| Compute | AWS ECS/Lambda | $1,000–5,000/month |
| Database | AWS RDS PostgreSQL + Replicas | $500–3,000/month |
| Caching | AWS ElastiCache (Redis) | $200–1,000/month |
| Search | Elasticsearch/OpenSearch | $500–2,000/month |
| Hot Storage | Cloudflare R2 | $300–1,000/month |
| Cold Storage | Backblaze B2 | $50–200/month |
| CDN | Cloudflare | $200–500/month |
| Auth | AWS Cognito or Supabase Auth | $100–500/month |
| Queues | AWS SQS/SNS | $50–200/month |
| Monitoring | Datadog or New Relic | $200–1,000/month |

**Key Changes from Phase 2:**
- Migrate database from Supabase to AWS RDS PostgreSQL with read replicas
- Dedicated microservices for OCR, notifications, and report generation
- Message queues (SQS) for async processing
- Elasticsearch for document full-text search
- Multi-tier storage (hot/cold) for cost optimization
- Comprehensive monitoring and observability

**Migration Triggers:**
- Supabase connection limits becoming an issue
- Need for read replicas
- Complex search requirements
- Microservices architecture needed
- Compliance/security requirements

---

## Storage Architecture

### Document Storage Strategy

| Scale | Primary Storage | Strategy |
|-------|----------------|----------|
| **0–10K users** | Supabase Storage | Included with Supabase Pro, simple integration |
| **10K–100K users** | Cloudflare R2 | Zero egress fees, S3-compatible, global CDN |
| **100K+ users** | R2 (hot) + B2 (cold) | Tiered storage with automatic lifecycle policies |

### Storage Cost Comparison (at 100K users, ~3TB)

| Provider | Storage Cost | Egress Cost | Total |
|----------|-------------|-------------|-------|
| Supabase Storage | $63/month | ~$500/month | ~$563/month |
| AWS S3 | $69/month | ~$500/month | ~$569/month |
| **Cloudflare R2** | $45/month | **$0** | **$45/month** |
| R2 + Backblaze B2 | ~$35/month | ~$10/month | ~$45/month |

### File Organization

```
{storage-bucket}/
├── {user_id}/
│   ├── documents/
│   │   ├── {document_id}.pdf
│   │   └── {document_id}.jpg
│   ├── photos/
│   │   ├── shutoffs/          # Emergency hub photos
│   │   ├── projects/          # Before/after photos
│   │   └── property/          # Property photos
│   └── thumbnails/
│       └── {document_id}_thumb.jpg
```

---

## Database Architecture

### Core Design Principles

1. **Row Level Security (RLS):** Users can only access their own data
2. **Indexing Strategy:** Index all foreign keys and frequently queried columns
3. **Soft Deletes:** Use `deleted_at` timestamps for data recovery
4. **Audit Trail:** Track `created_at` and `updated_at` on all tables

### Primary Tables

| Table | Purpose | Key Relationships |
|-------|---------|-------------------|
| `profiles` | User information, subscription status | Extends Supabase auth.users |
| `properties` | Home details, address, purchase info | Belongs to user |
| `documents` | Document metadata, OCR text | Belongs to property |
| `maintenance_tasks` | Scheduled and completed maintenance | Belongs to property |
| `emergency_info` | Shutoff locations, emergency contacts | Belongs to property |
| `systems` | HVAC, roof, appliances tracking | Belongs to property |

### Scaling Considerations

| Scale | Database Setup |
|-------|----------------|
| **0–50K users** | Single Supabase PostgreSQL instance |
| **50K–200K users** | Supabase with connection pooling (Supavisor) |
| **200K+ users** | AWS RDS PostgreSQL with read replicas |

---

## Caching Strategy

### What to Cache

| Data Type | Cache Duration | Priority |
|-----------|---------------|----------|
| User profile & preferences | 1 hour | High |
| Home profile data | 1 hour | High |
| Emergency hub data | 24 hours | High (critical for offline) |
| Maintenance schedule | 1 hour | High |
| Document metadata | 1 hour | Medium |
| Home value estimates | 24 hours | Medium |
| Weather data | 1 hour | Medium |

### Caching Implementation by Scale

| Scale | Solution | Cost |
|-------|----------|------|
| **0–10K users** | Supabase built-in + client-side | Included |
| **10K–100K users** | Upstash Redis (serverless) | $10–100/month |
| **100K+ users** | AWS ElastiCache (Redis Cluster) | $200–1,000/month |

---

## Authentication & Security

### Authentication Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Flutter    │     │   Next.js    │     │   Supabase   │
│     App      │     │     Web      │     │     Auth     │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       │  1. Login request  │                    │
       ├────────────────────┼───────────────────►│
       │                    │                    │
       │  2. JWT token      │                    │
       │◄───────────────────┼────────────────────┤
       │                    │                    │
       │  3. API calls with JWT                  │
       ├────────────────────┼───────────────────►│
       │                    │                    │
       │  4. RLS enforces   │                    │
       │     data access    │                    │
       │◄───────────────────┼────────────────────┤
```

### Supported Auth Methods

| Method | Platform | Notes |
|--------|----------|-------|
| Email/Password | All | Primary method |
| Google OAuth | All | Social login |
| Apple Sign-In | iOS, Web | Required for iOS apps |
| Magic Link | All | Passwordless option |

### Security Measures

| Layer | Implementation |
|-------|----------------|
| Data at Rest | AES-256 encryption (Supabase/AWS default) |
| Data in Transit | TLS 1.3 |
| API Security | JWT tokens, RLS policies |
| File Access | Signed URLs with expiration |
| Sensitive Data | Never store payment info; RevenueCat/Stripe handles |

---

## Payment Architecture

### Multi-Platform Payment Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     USER PURCHASES                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  📱 iOS              📱 Android           🌐 Web            │
│  App Store           Play Store           Stripe            │
│  In-App Purchase     In-App Purchase      Checkout          │
│       │                   │                   │              │
│       └───────────────────┼───────────────────┘              │
│                           ▼                                  │
│              ┌─────────────────────────┐                    │
│              │       RevenueCat        │                    │
│              │  (Single source of      │                    │
│              │   truth for subs)       │                    │
│              └───────────┬─────────────┘                    │
│                          │                                   │
│                          ▼                                   │
│              ┌─────────────────────────┐                    │
│              │    Webhook to API       │                    │
│              │                         │                    │
│              │  Updates user's         │                    │
│              │  subscription_tier      │                    │
│              │  in database            │                    │
│              └─────────────────────────┘                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Subscription Tiers

| Tier | Features | Platforms |
|------|----------|-----------|
| Free | Basic features, limited storage | All |
| Premium | Full features, priority support | All |
| Premium Plus | Multi-property, advanced analytics | All |

---

## Analytics Architecture

### Event Tracking Strategy

| Category | Example Events |
|----------|----------------|
| Onboarding | `onboarding_started`, `onboarding_completed`, `onboarding_skipped` |
| Core Features | `document_uploaded`, `maintenance_task_completed`, `emergency_hub_viewed` |
| Engagement | `app_opened`, `session_started`, `feature_discovered` |
| Monetization | `paywall_viewed`, `subscription_started`, `trial_started` |

### PostHog Implementation

| Feature | Use Case |
|---------|----------|
| Product Analytics | Track feature usage, funnels, retention |
| Session Replay | Debug user issues, understand UX problems |
| Feature Flags | Gradual rollouts, A/B testing |
| Experiments | Test pricing, onboarding flows |

---

## Offline Capabilities

### Emergency Hub (Offline-First)

The Emergency Hub must work without internet connectivity.

| Data | Storage | Sync Strategy |
|------|---------|---------------|
| Shutoff locations | SQLite (local) | Sync on app open |
| Shutoff photos | Local file system | Compressed, max 500KB each |
| Emergency contacts | SQLite (local) | Sync on app open |
| Insurance quick info | SQLite (local) | Sync on app open |

### Sync Strategy

```
┌─────────────────┐
│   App Launch    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ Check Network   │────►│  Online: Sync   │
│   Connection    │     │  with Supabase  │
└────────┬────────┘     └─────────────────┘
         │
         ▼ Offline
┌─────────────────┐
│  Use Local      │
│  SQLite Data    │
└─────────────────┘
```

---

## External API Integrations

### Property Data (ATTOM API)

| Endpoint | Purpose | Caching |
|----------|---------|---------|
| Property Detail | Home characteristics, year built | 7 days |
| AVM (Automated Valuation) | Home value estimate | 24 hours |
| Sales History | Purchase history, comps | 7 days |

**Cost Optimization:** Cache aggressively; home values don't change hourly.

### Weather Alerts (OpenWeatherMap/Tomorrow.io)

| Use Case | Trigger |
|----------|---------|
| Freeze warning | Temp < 32°F → "Protect pipes" alert |
| High wind | Wind > 50mph → "Secure outdoor items" alert |
| Heavy rain | Rain > 2in → "Check gutters" alert |
| Extreme heat | Temp > 95°F → "Check AC" alert |

### Mortgage Data (Plaid) – Future

| Feature | Purpose |
|---------|---------|
| Liabilities API | Auto-sync mortgage balance |
| Account verification | Verify homeownership |

---

## Deployment Strategy

### Mobile Apps

| Stage | Environment | Purpose |
|-------|-------------|---------|
| Development | Local Supabase | Developer testing |
| Staging | Supabase staging project | QA testing, beta users |
| Production | Supabase production project | Live users |

### Web App

| Platform | Purpose | Notes |
|----------|---------|-------|
| Vercel | Next.js hosting | Automatic previews, edge functions |
| Cloudflare Pages | Alternative | If deeper Cloudflare integration needed |

### CI/CD Pipeline

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   GitHub    │────►│   GitHub    │────►│   Deploy    │
│   Push      │     │   Actions   │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
   ┌───────────┐    ┌───────────┐    ┌───────────┐
   │  Flutter  │    │  Next.js  │    │ Supabase  │
   │  Build    │    │  Deploy   │    │ Migrations│
   │  (iOS/    │    │  (Vercel) │    │           │
   │  Android) │    │           │    │           │
   └───────────┘    └───────────┘    └───────────┘
```

---

## Monitoring & Observability

### Monitoring Stack by Scale

| Scale | Solution | Coverage |
|-------|----------|----------|
| **0–50K** | Sentry + PostHog + Supabase Dashboard | Errors, analytics, DB metrics |
| **50K–200K** | Add Uptime monitoring (Better Uptime) | API health, uptime |
| **200K+** | Datadog or New Relic | Full APM, infrastructure, logs |

### Key Metrics to Monitor

| Category | Metrics |
|----------|---------|
| Performance | API response time, database query time, app load time |
| Reliability | Error rate, uptime, failed jobs |
| Business | DAU/MAU, retention, conversion rate, churn |
| Infrastructure | CPU, memory, storage usage, connection pool |

---

## Migration Playbook

### Supabase Storage → Cloudflare R2

**Trigger:** Storage > 50GB or significant egress costs

**Strategy:**
1. Set up R2 bucket with same path structure
2. Update app to support both storage backends
3. New uploads go to R2
4. Background migration of existing files
5. Verify integrity
6. Switch all reads to R2
7. (Optional) Delete Supabase Storage after 30 days

**Downtime:** Zero

### Supabase → AWS RDS

**Trigger:** Connection limits, need for read replicas, compliance requirements

**Strategy:**
1. Set up RDS PostgreSQL with same schema
2. Enable Supabase logical replication
3. Sync data continuously
4. Test application with RDS endpoint
5. Switch traffic during low-usage window
6. Keep Supabase Auth or migrate to Cognito

**Downtime:** Minutes (during final cutover)

---

## Cost Projections

### Monthly Infrastructure Costs by Scale

| Users | Infrastructure | Third-Party APIs | Total |
|-------|---------------|------------------|-------|
| 1,000 | $50–100 | $500–600 | $550–700 |
| 10,000 | $200–400 | $600–800 | $800–1,200 |
| 50,000 | $800–1,500 | $1,000–2,000 | $1,800–3,500 |
| 100,000 | $2,000–4,000 | $2,000–4,000 | $4,000–8,000 |
| 500,000 | $8,000–15,000 | $5,000–10,000 | $13,000–25,000 |
| 1,000,000 | $15,000–30,000 | $10,000–20,000 | $25,000–50,000 |

**Largest Cost Drivers:**
1. ATTOM API (property data) – scales with active users
2. Storage + egress – scales with documents
3. Database – scales with queries
4. OCR processing – scales with uploads

---

## Technology Decision Summary

| Decision | Choice | Alternatives Considered |
|----------|--------|------------------------|
| Mobile Framework | Flutter | React Native, native iOS/Android |
| Web Framework | Next.js | Remix, SvelteKit, Flutter Web |
| Backend | Supabase | Firebase, custom Node.js, AWS Amplify |
| Database | PostgreSQL (via Supabase) | Firestore, MongoDB, PlanetScale |
| Storage | Supabase → Cloudflare R2 | AWS S3, Google Cloud Storage |
| Payments | RevenueCat + Stripe | Direct App Store/Play Store integration |
| Analytics | PostHog | Mixpanel, Amplitude, Firebase Analytics |
| Auth | Supabase Auth | Auth0, Firebase Auth, Clerk |

---

## Appendix: Service Links

| Service | Documentation |
|---------|--------------|
| Supabase | https://supabase.com/docs |
| Flutter | https://docs.flutter.dev |
| Next.js | https://nextjs.org/docs |
| Cloudflare R2 | https://developers.cloudflare.com/r2 |
| RevenueCat | https://docs.revenuecat.com |
| PostHog | https://posthog.com/docs |
| ATTOM API | https://api.developer.attomdata.com |
| Sentry | https://docs.sentry.io |

---

*Document Version: 1.0*  
*Last Updated: January 2026*
