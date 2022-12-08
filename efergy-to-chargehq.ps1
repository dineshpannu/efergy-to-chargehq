###############################################################################
# Efergy to Charge HQ Integration
#
# Modify these values to suit:
#

$EFERGY_TOKEN = "Your Efergy token"
$CHARGE_HQ_SITEID = "Your Charge-HQ site id"

#
#
###############################################################################


$EFERGY_URI = "http://www.energyhive.com/mobile_proxy/"
$CHARGE_HQ_URI = "https://api.chargehq.net/api/public/push-solar-data"

function ConvertToKw($power, $untis) {
    $kW = 0;

    if ($units -eq "kW") {
        $kW = $power
    } else {
        if ($power -le 75) {
            # These meters have errant measurements on the low side, probably due to measuring VA and not W.
            #
            $kW = 0
        }
        else {
            $kW = $power/1000
        }
    }

    return $kW
}

$json = Invoke-RestMethod -Uri "$($EFERGY_URI)getCurrentValuesSummary?token=$EFERGY_TOKEN"
#Write-Host ($json | ConvertTo-Json)

$payload = @{
    "apiKey" = $CHARGE_HQ_APIKEY
}

if (($null -ne $json) -and ($json.status -ne "error") -and (!$json.PSobject.Properties.name -match "error")) {
    
    $siteMeters = @{}

    foreach ($item in $json) {
        # Solar production. We assume only one sub meter. Modify if you have 2 solar inverters.
        #
        if ("PWER_SUB" -eq $item.cid) {
            $production = $item.data[0].PSObject.Properties.Value
            $productionKw = ConvertToKw $production $item.units
            $siteMeters["production_kw"] = $productionKw
            #Write-Host "Got production [$production] [$productionKw]"
        }

        # Consumption
        #
        elseif ("PWER" -eq $item.cid) {
            $consumption = $item.data[0].PSObject.Properties.Value
            $consumptionKw = ConvertToKw $consumption $item.units
            $siteMeters["consumption_kw"] = $consumptionKw
            #Write-Host "Got consumption [$consumption] [$consumptionKw]"
        }
    }

    if (($null -ne $consumptionkW) -and ($null -ne $productionkW)) {
        $siteMeters["net_import_kw"] = $consumptionKw - $productionKw
    }

    $payload["siteMeters"] = $siteMeters

} elseif ($json.status -eq "error"){

    $payload["error"] = $json.description
}
elseif ($json.PSobject.Properties.name -match "error") {

    $payload["error"] = $json.error.desc + ": " + $json.error.more
}

$payloadJson = $payload | ConvertTo-Json
#Write-Host $payloadJson

$response = Invoke-RestMethod -Uri $CHARGE_HQ_URI -Method Post -Body $payloadJson -ContentType "application/json"
#Write-Host $response
#$response | Out-File -FilePath .\hello.txt -Append
