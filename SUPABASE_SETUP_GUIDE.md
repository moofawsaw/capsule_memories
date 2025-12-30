# Supabase Setup Guide for Capsule App

## Problem Diagnosis

Your app shows "✅ Supabase initialized successfully" but database data isn't loading because:

1. **Environment variables are not set** - Supabase URL and anon key are empty
2. **Services fail silently** - Code attempts database operations before checking initialization
3. **Null-safety issues** - Direct access to `Supabase.instance.client` without null checks

## Solution: Set Environment Variables

### Option 1: Run with Command Line Arguments (Recommended for Development)

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Option 2: Create env.json File (For Persistent Configuration)

1. Create `env.json` in project root:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

2. Update your run configuration to load from env.json

### Option 3: VS Code Launch Configuration

Create/update `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Supabase)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://your-project.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=your-anon-key"
      ]
    }
  ]
}
```

## Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Settings** → **API**
4. Copy:
   - **Project URL** (use for SUPABASE_URL)
   - **anon public** key (use for SUPABASE_ANON_KEY)

## Verify Setup

After running with environment variables, check console for:

```
✅ Supabase initialized successfully
   URL: https://your-project.supabase.co
✅ Supabase client verified and ready
```

If you see warnings about empty credentials:

```
⚠️ Supabase credentials not configured
   Make sure to set SUPABASE_URL and SUPABASE_ANON_KEY environment variables
```

This means environment variables are not being passed correctly.

## Testing Database Connection

Once configured, you should see data loading in:
- `/memories` screen
- User profiles
- Notifications
- Any screen that fetches from Supabase

## Troubleshooting

### Issue: "Supabase not initialized"

**Solution**: Verify environment variables are set correctly

```bash
# Check if variables are accessible (add this temporarily to main.dart)
print('URL: ${String.fromEnvironment('SUPABASE_URL')}');
print('Key length: ${String.fromEnvironment('SUPABASE_ANON_KEY').length}');
```

### Issue: "Null check operator used on a null value"

**Solution**: This error occurs when code tries to access Supabase client before initialization. The updated services now handle this gracefully.

### Issue: Data not loading after initialization

**Solution**: 
1. Check network tab in browser DevTools for failed requests
2. Verify RLS policies in Supabase allow data access
3. Check if user is authenticated (some tables require auth)

## Security Note

⚠️ **NEVER commit `env.json` or credentials to git**

Add to `.gitignore`:
```
env.json
.env
*.env
```

The anon key is safe to use in frontend code (it's rate-limited by Supabase and protected by RLS policies).