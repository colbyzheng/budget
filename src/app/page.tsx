import { Suspense } from "react";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { auth } from "@/lib/auth";
import { SignOutButton } from "./sign-out-button";

// The session is read per request, so it streams in behind Suspense (Cache Components rule).
async function Greeting() {
  const session = await auth.api.getSession({ headers: await headers() });
  if (!session) redirect("/sign-in");
  return <h1 className="text-2xl font-semibold">Hi, {session.user.name.split(" ")[0]}</h1>;
}

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-6">
      <Suspense fallback={<div className="h-8 w-32 animate-pulse rounded bg-zinc-200" />}>
        <Greeting />
      </Suspense>
      <p className="text-zinc-500">Budget is set up. Transactions arrive in M2–M3.</p>
      <SignOutButton />
    </main>
  );
}
