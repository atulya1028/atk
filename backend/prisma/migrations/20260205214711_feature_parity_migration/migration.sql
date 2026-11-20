/*
  Warnings:

  - You are about to drop the column `value` on the `Answer` table. All the data in the column will be lost.
  - You are about to drop the column `order` on the `Question` table. All the data in the column will be lost.
  - You are about to drop the column `type` on the `Question` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE `Answer` DROP COLUMN `value`,
    ADD COLUMN `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    ADD COLUMN `valueNumber` DECIMAL(65, 30) NULL,
    ADD COLUMN `valueText` TEXT NULL;

-- AlterTable
ALTER TABLE `Option` ADD COLUMN `category` VARCHAR(191) NOT NULL DEFAULT 'standard',
    ADD COLUMN `sortOrder` INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE `Question` DROP COLUMN `order`,
    DROP COLUMN `type`,
    ADD COLUMN `inputType` VARCHAR(191) NOT NULL DEFAULT 'text',
    ADD COLUMN `isRequired` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `parentQuestionId` INTEGER NULL,
    ADD COLUMN `sectionId` INTEGER NULL,
    ADD COLUMN `sortOrder` INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE `Submission` ADD COLUMN `status` VARCHAR(191) NOT NULL DEFAULT 'draft';

-- CreateTable
CREATE TABLE `Section` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `parentId` INTEGER NULL,
    `slug` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `sectionType` VARCHAR(191) NOT NULL DEFAULT 'general',
    `sortOrder` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `Section_slug_key`(`slug`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `QuestionDependency` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `dependentQuestionId` INTEGER NOT NULL,
    `triggerQuestionId` INTEGER NOT NULL,
    `operator` VARCHAR(191) NOT NULL DEFAULT 'eq',
    `triggerValue` VARCHAR(191) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `AnswerChoice` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `answerId` INTEGER NOT NULL,
    `questionOptionId` INTEGER NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `Section` ADD CONSTRAINT `Section_parentId_fkey` FOREIGN KEY (`parentId`) REFERENCES `Section`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Question` ADD CONSTRAINT `Question_sectionId_fkey` FOREIGN KEY (`sectionId`) REFERENCES `Section`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Question` ADD CONSTRAINT `Question_parentQuestionId_fkey` FOREIGN KEY (`parentQuestionId`) REFERENCES `Question`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `QuestionDependency` ADD CONSTRAINT `QuestionDependency_dependentQuestionId_fkey` FOREIGN KEY (`dependentQuestionId`) REFERENCES `Question`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `QuestionDependency` ADD CONSTRAINT `QuestionDependency_triggerQuestionId_fkey` FOREIGN KEY (`triggerQuestionId`) REFERENCES `Question`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AnswerChoice` ADD CONSTRAINT `AnswerChoice_answerId_fkey` FOREIGN KEY (`answerId`) REFERENCES `Answer`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AnswerChoice` ADD CONSTRAINT `AnswerChoice_questionOptionId_fkey` FOREIGN KEY (`questionOptionId`) REFERENCES `Option`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
