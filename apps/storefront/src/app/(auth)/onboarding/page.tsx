import { Suspense } from "react";
import { OnboardingContent } from "./OnboardingContent";

function OnboardingFallback() {
  return (
    <main className="min-h-screen">
      <div className="mx-auto max-w-xl animate-pulse p-6">
        <div className="h-8 w-48 rounded bg-muted" />
        <div className="mt-6 h-32 rounded bg-muted" />
      </div>
    </main>
  );
}

export default function OnboardingPage() {
  return (
    <Suspense fallback={<OnboardingFallback />}>
      <OnboardingContent />
    </Suspense>
  );
}