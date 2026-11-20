CREATE TABLE IF NOT EXISTS "Doctor" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "otp" TEXT,
    "otpCreatedAt" DATETIME,
    "phoneNumber" TEXT,
    "specialization" TEXT,
    "servicePincode" TEXT,
    "isProfileComplete" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS "Doctor_email_key" ON "Doctor"("email");
