#Alttaki iki satırda task schedule uygulamasında oluşturmak istediğimiz isimde bir job oluşturuldu ise bunun kaldırılmasını sağlıyoruz.
#Eğer zaten böyle bir job yoksa hata yazısı verip uygulama job oluşturmaya devam ediyor bunun yaşanmaması için ErrorAction ekledik.
Get-ScheduledJob -Name "%10 Üzerinde Cpu Kullanan Uygulamalar" -ErrorAction SilentlyContinue
Unregister-ScheduledJob -Name "%10 Üzerinde Cpu Kullanan Uygulamalar" -force -ErrorAction SilentlyContinue
#Bir alttaki satırda jobumuz için önceden bir trigger atadık bu trigger dakika başı jobumuz çalışmasını sağlıyor.Lütfen Tarihi kendi bilgisayarınıza göre değiştiriniz
$t = New-JobTrigger -Once -At "1/19/2022 0am" -RepetitionInterval (New-TimeSpan -Minute 1) -RepetitionDuration ([TimeSpan]::MaxValue)
#Bir alttaki satırda jobu oluşturduk ve önceden oluşturduğumuz triggerı ekledik.
Register-ScheduledJob -Name "%10 Üzerinde Cpu Kullanan Uygulamalar" -Trigger $t -ScriptBlock `
{
#Burdaki kod bloğunda Get-Process kullanarak istediğimiz sonuca ulaşamadığımız için Get-Counter kullandık.
#Aşağıdaki satırlara yorum satırı girdğimiz zaman kod kırılıyor bu yüzden bu blok için yorumları buraya ekledik.
#Sort ile CookedValue yani cpu değerinin azalarak sıranlanmasını sağladık.
#Where ile cpu değeri %10 dan aşağıda olan processlerin ayrıca zaten en üstte yer alan ve hiç değişmeyen _total ve idle değerlerinin ekrana gelmesini engelledik.
#Where komutunun içindeki -gt komutunun değerini değiştirerek istediğiniz yüzdelik dilimdeki programları çağırabilirsiniz. Örn. 10 yerine 0 yazarsanız 0 dan fazla cpu kullanan uygulamalr gelecektir.
#Tekrar Select kullanarak değerleri ekrana aldık.
#Son olarak Out-File ile değerlerimizi bir log dosyasına yazdırdık. Burda düzgün çıktı alabilmek adına lütfen kendi bilgisayarnızda kaydetmek istediğiniz dosya yolunu ekleyiniz.
 Get-Counter "\Process(*)\% Processor Time" -ErrorAction SilentlyContinue `
|Select -ExpandProperty CounterSamples `
|Sort CookedValue -Descending `
|Where {$_.CookedValue/$env:NUMBER_OF_PROCESSORS -gt 10 -and $_.InstanceName -notin "_total","idle"} `
|Select `
@{n="DATE/TTIME";e={$_.TimeStamp}},
@{n="NAME";e={$_.InstanceName}},
@{n="CPU %";e={[Decimal]::Round(($_.CookedValue/$env:NUMBER_OF_PROCESSORS),2)}},
@{n="PATH";e={$_.Path}} `
|Out-File -FilePath C:\temp\cikti.log

}
#Eğer jobun trigger kullanmadan çalışmasını istiyorsanız yukarıda Register-ScheduledJob kısmındaki -trigger $t yi kaldırıp aşağıyı yorum satırından çıkartın
#Bu sayede kod her çalıştığında job da çalışacaktır
#Start-Job -DefinitionName "%10 Üzerinde Cpu Kullanan Uygulamalar"