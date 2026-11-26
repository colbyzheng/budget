"use client";

import { useRouter } from "next/navigation";
import { authClient } from "@/lib/auth-client";

export function SignOutButton() {
  const router = useRouter();
  return (
    <button
      className="text-sm underline"
      onClick={() => authClient.signOut().then(() => router.push("/sign-in"))}
    >
      Sign out
    </button>
  );
}
