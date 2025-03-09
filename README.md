# درگاه کارت به کارت (تایید خودکار کارت به کارت در شبکه شتاب)

این پروژه یک سیستم تایید خودکار کارت به کارت در شبکه شتاب است که با استفاده از **فلاتر (Flutter)** توسعه داده شده است. این سیستم با تحلیل پیامک‌های دریافتی از سرشماره‌های بانکی، اطلاعات واریز به حساب را استخراج کرده و به `endpoint` تعریف‌شده در برنامه ارسال می‌کند.

## دانلود نسخه‌ها
- [دانلود نسخه ساین شده (app-release.apk)](release/app-release.apk)
- [دانلود نسخه ساین نشده (app-release-unsigned.apk)](release/app-release-unsigned.apk)

## ویژگی‌های پروژه

- **تایید خودکار تراکنش‌ها**: با تحلیل پیامک‌های بانکی، اطلاعات واریز به صورت خودکار استخراج و تایید می‌شود.
- **پشتیبانی از سرشماره‌های بانکی**: امکان تعریف و مدیریت سرشماره‌های بانکی مختلف برای تحلیل پیامک‌ها.
- **قابلیت شخصی‌سازی API**: امکان شخصی‌سازی `API` همراه با `API Key` برای یکپارچه‌سازی با سیستم‌های دیگر.
- **خواندن خودکار پیامک‌ها**: سیستم به صورت خودکار پیامک‌های دریافتی را خوانده و پردازش می‌کند.
- **اجرا در پس‌زمینه**: حتی زمانی که برنامه در حال اجرا نیست، سیستم در پس‌زمینه فعال است و پیامک‌ها را بررسی می‌کند.

## روش کار

1. **دریافت پیامک**: سیستم پیامک‌های دریافتی از سرشماره‌های بانکی را دریافت می‌کند.
2. **تحلیل پیامک**: متن پیامک برای استخراج اطلاعات واریز (مانند مبلغ، شماره کارت مبدا و مقصد) تحلیل می‌شود.
3. **ارسال اطلاعات**: اطلاعات استخراج‌شده به `endpoint` تعریف‌شده در برنامه ارسال می‌شود.
4. **تایید تراکنش**: سیستم تراکنش را تایید کرده و نتیجه را به کاربر نمایش می‌دهد.

## نحوه استفاده

برای استفاده از این پروژه، مراحل زیر را دنبال کنید:

1. **نصب و راه‌اندازی**: پروژه را از ریپوزیتوری گیت‌هاب کلون کرده و با استفاده از فلاتر اجرا کنید.
2. **تعریف سرشماره‌ها**: سرشماره‌های بانکی مورد نظر را در تنظیمات برنامه تعریف کنید.
3. **تنظیم API**: `endpoint` و `API Key` را در تنظیمات برنامه وارد کنید.
4. **اجرا**: برنامه را اجرا کرده و از قابلیت تایید خودکار تراکنش‌ها استفاده نمایید.

## نیازمندی‌ها

- **فلاتر (Flutter)**: نسخه 3.0 یا بالاتر.
- **دسترسی به پیامک‌ها**: برنامه نیاز به دسترسی به پیامک‌های دریافتی دارد.
- **API Endpoint**: یک `endpoint` برای دریافت اطلاعات واریز.

---

این پروژه به شما کمک می‌کند تا تراکنش‌های کارت به کارت را به صورت خودکار تایید کرده و فرآیندهای مالی خود را ساده‌تر کنید.
---


# Card-to-Card Gateway (Automatic Verification in Shetab Network)

This project is an automatic card-to-card verification system in the Shetab network, developed using **Flutter**. The system analyzes incoming SMS messages from bank-specific numbers, extracts deposit information, and sends it to a predefined `endpoint` in the application.

# Download

- [Signed (app-release.apk)](release/app-release.apk)
- [UnSigned (app-release-unsigned.apk)](release/app-release-unsigned.apk)


## Project Features

- **Automatic Transaction Verification**: By analyzing bank SMS messages, deposit information is automatically extracted and verified.
- **Support for Bank-Specific Numbers**: Ability to define and manage various bank-specific numbers for SMS analysis.
- **Customizable API**: Ability to customize the `API` with an `API Key` for integration with other systems.
- **Automatic SMS Reading**: The system automatically reads and processes incoming SMS messages.
- **Background Execution**: The system remains active in the background, even when the app is not running, and continues to check SMS messages.

## How It Works

1. **Receiving SMS**: The system receives SMS messages from bank-specific numbers.
2. **Analyzing SMS**: The SMS text is analyzed to extract deposit information (e.g., amount, source, and destination card numbers).
3. **Sending Information**: The extracted information is sent to the predefined `endpoint` in the application.
4. **Transaction Verification**: The system verifies the transaction and displays the result to the user.

## How to Use

To use this project, follow these steps:

1. **Installation and Setup**: Clone the project from the GitHub repository and run it using Flutter.
2. **Define Bank-Specific Numbers**: Define the desired bank-specific numbers in the application settings.
3. **Configure API**: Enter the `endpoint` and `API Key` in the application settings.
4. **Run**: Launch the application and use the automatic transaction verification feature.

## Requirements

- **Flutter**: Version 3.0 or higher.
- **SMS Access**: The application requires access to incoming SMS messages.
- **API Endpoint**: An `endpoint` to receive deposit information.


---

This project helps you automatically verify card-to-card transactions and simplifies your financial processes.