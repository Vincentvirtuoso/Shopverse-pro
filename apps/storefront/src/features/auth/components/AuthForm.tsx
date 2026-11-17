"use client";

import Link from "next/link";
import { useActionState, useState } from "react";
import { EyeIcon, EyeOffIcon, LockIcon } from "lucide-react";
import { Button, Input } from "@splenddev/kreativ-ui/components";
import { loginAction, signupAction } from "../actions";

interface AuthFormProps {
  mode: "login" | "signup";
  /** Render a Google button only when provided (e.g. Supabase OAuth). */
  onGoogleSignIn?: () => void;
}

const labelClass = "text-sm font-medium text-foreground";

function GoogleIcon() {
  return (
    <svg viewBox="0 0 24 24" className="size-4.5" aria-hidden="true">
      <path
        fill="#4285F4"
        d="M23.5 12.3c0-.8-.1-1.6-.2-2.3H12v4.5h6.5a5.6 5.6 0 0 1-2.4 3.6v3h3.9c2.3-2.1 3.5-5.2 3.5-8.8Z"
      />
      <path
        fill="#34A853"
        d="M12 24c3.2 0 6-1.1 7.9-2.9l-3.9-3c-1.1.7-2.4 1.1-4 1.1-3.1 0-5.7-2.1-6.6-4.9H1.4v3.1A12 12 0 0 0 12 24Z"
      />
      <path
        fill="#FBBC05"
        d="M5.4 14.3a7.2 7.2 0 0 1 0-4.6V6.6H1.4a12 12 0 0 0 0 10.8l4-3.1Z"
      />
      <path
        fill="#EA4335"
        d="M12 4.8c1.8 0 3.3.6 4.6 1.8l3.4-3.4A12 12 0 0 0 1.4 6.6l4 3.1C6.3 6.9 8.9 4.8 12 4.8Z"
      />
    </svg>
  );
}

export function AuthForm({ mode, onGoogleSignIn }: AuthFormProps) {
  const isSignup = mode === "signup";
  const action = isSignup ? signupAction : loginAction;

  const [state, formAction, isPending] = useActionState(action, null);
  const [showPassword, setShowPassword] = useState(false);

  const hasError = state?.status === "error";

  return (
    <form action={formAction} className="space-y-4">
      {onGoogleSignIn && (
        <>
          <Button
            type="button"
            variant="outline"
            fullWidth
            leftIcon={<GoogleIcon />}
            onClick={onGoogleSignIn}
          >
            Continue with Google
          </Button>

          <div className="flex items-center gap-3 text-xs text-text-muted">
            <span className="h-px flex-1 bg-border" />
            or
            <span className="h-px flex-1 bg-border" />
          </div>
        </>
      )}

      {isSignup && (
        <div className="space-y-1.5">
          <label htmlFor="displayName" className={labelClass}>
            Full name
          </label>
          <Input
            id="displayName"
            name="displayName"
            type="text"
            autoComplete="name"
            required
            placeholder="Your name"
            fullWidth
            error={hasError}
          />
        </div>
      )}

      <div className="space-y-1.5">
        <label htmlFor="email" className={labelClass}>
          Email address
        </label>
        <Input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          aria-invalid={hasError || undefined}
          placeholder="you@example.com"
          fullWidth
          error={hasError}
        />
      </div>

      <div className="space-y-1.5">
        <div className="flex items-center justify-between gap-3">
          <label htmlFor="password" className={labelClass}>
            Password
          </label>

          {!isSignup && (
            <Link
              href="/forgot-password"
              className="text-xs font-medium text-brand hover:underline"
            >
              Forgot password?
            </Link>
          )}
        </div>

        <div className="relative">
          <Input
            id="password"
            name="password"
            type={showPassword ? "text" : "password"}
            autoComplete={isSignup ? "new-password" : "current-password"}
            minLength={8}
            required
            aria-invalid={hasError || undefined}
            aria-describedby={isSignup ? "password-hint" : undefined}
            placeholder={isSignup ? "At least 8 characters" : "Your password"}
            fullWidth
            error={hasError}
            inputClassName="pr-11"
          />
          <button
            type="button"
            onClick={() => setShowPassword((value) => !value)}
            aria-label={showPassword ? "Hide password" : "Show password"}
            aria-pressed={showPassword}
            className="absolute inset-y-0 right-0 flex w-11 items-center justify-center text-text-muted transition hover:text-foreground focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-foreground"
          >
            {showPassword ? (
              <EyeOffIcon className="size-4.5" aria-hidden="true" />
            ) : (
              <EyeIcon className="size-4.5" aria-hidden="true" />
            )}
          </button>
        </div>

        {isSignup && (
          <p id="password-hint" className="text-xs text-text-muted">
            Use 8 or more characters.
          </p>
        )}
      </div>

      {state && (
        <p
          role={hasError ? "alert" : "status"}
          className={`rounded-lg border px-4 py-3 text-sm ${
            hasError
              ? "border-destructive/30 bg-destructive/5 text-destructive"
              : "border-success/30 bg-success/5 text-success"
          }`}
        >
          {state.message}
        </p>
      )}

      <Button
        type="submit"
        fullWidth
        size="lg"
        isLoading={isPending}
        // loadingText="Please wait..."
        leftIcon={
          !isPending ? (
            <LockIcon className="size-4" aria-hidden="true" />
          ) : undefined
        }
      >
        {isSignup ? "Create account" : "Sign in"}
      </Button>

      {isSignup && (
        <p className="text-xs leading-5 text-text-muted">
          By creating an account, you agree to Shopverse&apos;s{" "}
          <Link href="/terms" className="underline hover:text-foreground">
            Terms
          </Link>{" "}
          and{" "}
          <Link href="/privacy" className="underline hover:text-foreground">
            Privacy Policy
          </Link>
          .
        </p>
      )}

      <div className="flex items-center gap-3 pt-2 text-xs text-text-muted">
        <span className="h-px flex-1 bg-border" />
        {isSignup ? "Already a member?" : "New to Shopverse?"}
        <span className="h-px flex-1 bg-border" />
      </div>

      <Link
        href={isSignup ? "/login" : "/signup"}
        className="flex w-full items-center justify-center rounded-lg border border-border bg-surface px-5 py-3 text-sm font-medium text-foreground transition hover:bg-surface-muted focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-foreground"
      >
        {isSignup ? "Sign in to your account" : "Create your Shopverse account"}
      </Link>
    </form>
  );
}
