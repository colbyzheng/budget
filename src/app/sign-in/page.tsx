"use client";

import { authClient } from "@/lib/auth-client";

export default function SignInPage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 p-6">
      <h1 className="text-2xl font-semibold">Budget</h1>
      <button
        className="rounded-lg bg-black px-5 py-3 text-white dark:bg-white dark:text-black"
        onClick={() => authClient.signIn.social({ provider: "google", callbackURL: "/" })}
      >
        Sign in with Google
      </button>
    </main>
  );
}
