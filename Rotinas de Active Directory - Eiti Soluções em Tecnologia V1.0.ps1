##############################################################
#       
#  Eiti Soluções em TI
#  Script de Execução de Rotinas relacionadas a AD
#  Author: André Luiz Batista   
#  Date: 23/06/2020 
#
##############################################################

# Limpa Variáveis Antigas

Remove-Variable * -ErrorAction SilentlyContinue

### Variáveis do Script
 
# Data/Hora

$dia = Get-Date -Format dd
$mes = Get-Date -Format MMMM
$ano = Get-Date -Format yyyy
$hora = Get-Date -Format HH
$minuto = Get-Date -Format mm
$dominio = (gwmi WIN32_ComputerSystem).Domain
$espera = '60'

# Diretórios Utilizados

$diretorio = New-Item -Path ".\" -Name "Rotinas - Eiti Soluções" -ItemType "directory" -Force
cd $diretorio
$reportesaudead = ".\Reporte da Saude do AD - Executado em $dia de $mes de $ano às $hora horas e $minuto minutos.htm"
$reporteusuariosinativos = ".\Reporte de Usuarios Ativos e Inativos no AD - Executado em $dia de $mes de $ano às $hora horas e $minuto minutos.htm"

##################################### INICIO DO REPORTE DE SAUDE DO AD #####################################

if((test-path $reportesaudead) -like $false) 
{ 
new-item $reportesaudead -type file 
} 

# Formatação do Reporte HTML

$report = $reportesaudead 
 
Clear-Content $report  
Add-Content $report "<html>"  
Add-Content $report "<head>"  
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"  
Add-Content $report '<title>Status da Saúde do AD</title>'  
Add-Content $report '<STYLE TYPE="text/css">'  
Add-Content $report  "<!--"  
Add-Content $report  "td {"  
Add-Content $report  "font-family: Tahoma;"  
Add-Content $report  "font-size: 11px;"  
Add-Content $report  "border-top: 1px solid #999999;"  
Add-Content $report  "border-right: 1px solid #999999;"  
Add-Content $report  "border-bottom: 1px solid #999999;"  
Add-Content $report  "border-left: 1px solid #999999;"  
Add-Content $report  "padding-top: 0px;"  
Add-Content $report  "padding-right: 0px;"  
Add-Content $report  "padding-bottom: 0px;"  
Add-Content $report  "padding-left: 0px;"  
Add-Content $report  "}"  
Add-Content $report  "body {"  
Add-Content $report  "margin-left: 5px;"  
Add-Content $report  "margin-top: 5px;"  
Add-Content $report  "margin-right: 0px;"  
Add-Content $report  "margin-bottom: 10px;"  
Add-Content $report  ""  
Add-Content $report  "table {"  
Add-Content $report  "border: thin solid #000000;"  
Add-Content $report  "}"  
Add-Content $report  "-->"  
Add-Content $report  "</style>"  
Add-Content $report "</head>"  
Add-Content $report "<body>"  
Add-Content $report  "<table width='100%'>"  
Add-Content $report  "<tr bgcolor=#C1D200>"  
Add-Content $report  "<td colspan='7' height='25' align='center'>"  
Add-Content $report  "<font face='tahoma' color='#000000' size='4'><strong>[$dominio] Status da Saúde do AD</strong></font>"  
Add-Content $report  "</td>"  
Add-Content $report  "</tr>"  
Add-Content $report  "</table>"
Add-Content $report  "<table width='100%'>"  
Add-Content $report  "<tr bgcolor='GainsBoro'>"  
Add-Content $report  "<td width='5%' align='center'><B>Servidor</B></td>"  
Add-Content $report  "<td width='10%' align='center'><B>Responde a ping?</B></td>"  
Add-Content $report  "<td width='10%' align='center'><B>Status do serviço Netlogon</B></td>"  
Add-Content $report  "<td width='10%' align='center'><B>Status do serviço NTDS</B></td>"  
Add-Content $report  "<td width='10%' align='center'><B>Status do serviço DNS</B></td>"  
Add-Content $report  "<td width='10%' align='center'><B>Acessa o Netlogon?</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>Está replicando?</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>Demais serviços relacionados estão rodando?</B></td>" 
  
Add-Content $report "</tr>"  
 
# Lista todos os DC's do domínio:
 
$getForest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest() 
 
$DCServers = $getForest.domains | ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name}  
 
# Teste de Ping
 
foreach ($DC in $DCServers){ 
$Servidor = $DC 
                Add-Content $report "<tr>" 
if ( Test-Connection -ComputerName $DC -Count 1 -ErrorAction SilentlyContinue ) { 
Write-Host $DC `t $DC `t Ping Success -ForegroundColor Green 
  
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $Servidor</B></td>"  
                Add-Content $report "<td bgcolor= #7EDE00 align=center>  <B>Responde</B></td>"  
 
# Valida o serviço Netlogon:

        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "Netlogon" -ErrorAction SilentlyContinue} -ArgumentList $DC 
                wait-job $serviceStatus -timeout $espera 
                if($serviceStatus.state -like "Running") 
                { 
                 Write-Host $DC `t Netlogon Service TimeOut -ForegroundColor Yellow 
                 Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
                 stop-job $serviceStatus 
                } 
                else 
                { 
                $serviceStatus1 = Receive-job $serviceStatus 
                 if ($serviceStatus1.status -eq "Running") { 
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green  
                $svcName = $serviceStatus1.name  
                $svcState = $serviceStatus1.status           
                Add-Content $report "<td bgcolor= #7EDE00 align=center><B>Rodando</B></td>"  
                  } 
                 else  
                  {  
                 Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red  
               $svcName = $serviceStatus1.name  
               $svcState = $serviceStatus1.status           
               Add-Content $report "<td bgcolor= 'Red' align=center><B>Parado</B></td>"  
                  }  
                } 

# Valida o serviço NTDS:

        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "NTDS" -ErrorAction SilentlyContinue} -ArgumentList $DC 
                wait-job $serviceStatus -timeout $espera 
                if($serviceStatus.state -like "Running") 
                { 
                 Write-Host $DC `t NTDS Service TimeOut -ForegroundColor Yellow 
                 Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
                 stop-job $serviceStatus 
                } 
                else 
                { 
                $serviceStatus1 = Receive-job $serviceStatus 
                 if ($serviceStatus1.status -eq "Running") { 
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green  
                $svcName = $serviceStatus1.name  
                $svcState = $serviceStatus1.status           
                Add-Content $report "<td bgcolor= #7EDE00 align=center><B>Rodando</B></td>"  
                  } 
                 else  
                  {  
                 Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red  
               $svcName = $serviceStatus1.name  
               $svcState = $serviceStatus1.status           
               Add-Content $report "<td bgcolor= 'Red' align=center><B>Parado</B></td>"  
                  }  
                } 

# Valida o serviço DNS:

        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "DNS" -ErrorAction SilentlyContinue} -ArgumentList $DC 
                wait-job $serviceStatus -timeout $espera 
                if($serviceStatus.state -like "Running") 
                { 
                 Write-Host $DC `t DNS Server Service TimeOut -ForegroundColor Yellow 
                 Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
                 stop-job $serviceStatus 
                } 
                else 
                { 
                $serviceStatus1 = Receive-job $serviceStatus 
                 if ($serviceStatus1.status -eq "Running") { 
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green  
                $svcName = $serviceStatus1.name  
                $svcState = $serviceStatus1.status           
                Add-Content $report "<td bgcolor= #7EDE00 align=center><B>Rodando</B></td>"  
                  } 
                 else  
                  {  
                 Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red  
               $svcName = $serviceStatus1.name  
               $svcState = $serviceStatus1.status           
               Add-Content $report "<td bgcolor= 'Red' align=center><B>Parado</B></td>"  
                  }  
                } 

# Testa o acesso ao NetLogon:
 
               add-type -AssemblyName microsoft.visualbasic  
               $cmp = "microsoft.visualbasic.strings" -as [type] 
               $sysvol = start-job -scriptblock {dcdiag /test:netlogons /s:$($args[0])} -ArgumentList $DC 
               wait-job $sysvol -timeout $espera 
               if($sysvol.state -like "Running") 
               { 
               Write-Host $DC `t Netlogons Test TimeOut -ForegroundColor Yellow 
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
               stop-job $sysvol 
               } 
               else 
               { 
               $sysvol1 = Receive-job $sysvol 
               if($cmp::instr($sysvol1, "passed test NetLogons")) 
                  { 
                  Write-Host $DC `t Netlogons Test passed -ForegroundColor Green 
                  Add-Content $report "<td bgcolor= #7EDE00 align=center><B>Netlogon Acessível</B></td>" 
                  } 
               else 
                  { 
                  Write-Host $DC `t Netlogons Test Failed -ForegroundColor Red 
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>Netlogon Inacessível</B></td>" 
                  } 
                } 

# Valida a replicação entre os servidores:
 
               add-type -AssemblyName microsoft.visualbasic  
               $cmp = "microsoft.visualbasic.strings" -as [type] 
               $sysvol = start-job -scriptblock {dcdiag /test:Replications /s:$($args[0])} -ArgumentList $DC 
               wait-job $sysvol -timeout $espera 
               if($sysvol.state -like "Running") 
               { 
               Write-Host $DC `t Replications Test TimeOut -ForegroundColor Yellow 
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
               stop-job $sysvol 
               } 
               else 
               { 
               $sysvol1 = Receive-job $sysvol 
               if($cmp::instr($sysvol1, "passed test Replications")) 
                  { 
                  Write-Host $DC `t Replications Test passed -ForegroundColor Green 
                  Add-Content $report "<td bgcolor= #7EDE00 align=center><B>Sim</B></td>" 
                  } 
               else 
                  { 
                  Write-Host $DC `t Replications Test Failed -ForegroundColor Red 
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>Não</B></td>" 
                  } 
                } 

# Valida o status dos serviços:

               add-type -AssemblyName microsoft.visualbasic  
               $cmp = "microsoft.visualbasic.strings" -as [type] 
               $sysvol = start-job -scriptblock {dcdiag /test:Services /s:$($args[0])} -ArgumentList $DC 
               wait-job $sysvol -timeout $espera 
               if($sysvol.state -like "Running") 
               { 
               Write-Host $DC `t Services Test TimeOut -ForegroundColor Yellow 
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
               stop-job $sysvol 
               } 
               else 
               { 
               $sysvol1 = Receive-job $sysvol 
               if($cmp::instr($sysvol1, "passed test Services")) 
                  { 
                  Write-Host $DC `t Services Test passed -ForegroundColor Green 
                  Add-Content $report "<td bgcolor= #7EDE00 align=center><B>Sim</B></td>" 
                  } 
               else 
                  { 
                  Write-Host $DC `t Services Test Failed -ForegroundColor Red 
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>Não</B></td>" 
                  } 
                } 
                 
}  
else 
              { 
Write-Host $DC `t $DC `t Ping Fail -ForegroundColor Red 
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B>$Servidor</B></td>"  
        Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Falhou</B></td>"  
        Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"  
        Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"  
        Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"  
        Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
        Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
        Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
}          
        
}  
 
Add-Content $report "</tr>" 

# Fim do conteúdo HTML
 
Add-Content $report  "</table>"  
Add-Content $report "</body>"  
Add-Content $report "</html>"

##################################### FIM DO REPORTE DE SAUDE DO AD #####################################

################################ INICIO DO REPORTE DE USUARIOS INATIVOS DO AD ###########################
 
 
if((test-path $reporteusuariosinativos) -like $false) 
{ 
new-item $reporteusuariosinativos -type file 
} 

# Formatação do reporte HTML

$reportinativos = $reporteusuariosinativos 
 
Clear-Content $reportinativos  
Add-Content $reportinativos "<html>"  
Add-Content $reportinativos "<head>"  
Add-Content $reportinativos "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"  
Add-Content $reportinativos '<title>Status da Saúde do AD</title>'  
Add-Content $reportinativos '<STYLE TYPE="text/css">'  
Add-Content $reportinativos  "<!--"  
Add-Content $reportinativos  "td {"  
Add-Content $reportinativos  "font-family: Tahoma;"  
Add-Content $reportinativos  "font-size: 11px;"  
Add-Content $reportinativos  "border-top: 1px solid #999999;"  
Add-Content $reportinativos  "border-right: 1px solid #999999;"  
Add-Content $reportinativos  "border-bottom: 1px solid #999999;"  
Add-Content $reportinativos  "border-left: 1px solid #999999;"  
Add-Content $reportinativos  "padding-top: 0px;"  
Add-Content $reportinativos  "padding-right: 0px;"  
Add-Content $reportinativos  "padding-bottom: 0px;"  
Add-Content $reportinativos  "padding-left: 0px;"  
Add-Content $reportinativos  "}"  
Add-Content $reportinativos  "body {"  
Add-Content $reportinativos  "margin-left: 5px;"  
Add-Content $reportinativos  "margin-top: 5px;"  
Add-Content $reportinativos  "margin-right: 0px;"  
Add-Content $reportinativos  "margin-bottom: 10px;"  
Add-Content $reportinativos  ""  
Add-Content $reportinativos  "table {"  
Add-Content $reportinativos  "border: thin solid #000000;"  
Add-Content $reportinativos  "}"  
Add-Content $reportinativos  "-->"  
Add-Content $reportinativos  "</style>"  
Add-Content $reportinativos "</head>"  
Add-Content $reportinativos "<body>"  
Add-Content $reportinativos  "<table width='100%'>"  
Add-Content $reportinativos  "<tr bgcolor=#C1D200>"  
Add-Content $reportinativos  "<td colspan='7' height='25' align='center'>"  
Add-Content $reportinativos  "<font face='tahoma' color='#000000' size='4'><strong>[$dominio] Usuários Inativos no AD a mais de 90 dias</strong></font>"  
Add-Content $reportinativos  "</td>"  
Add-Content $reportinativos  "</tr>"  
Add-Content $reportinativos  "</table>"
Add-Content $reportinativos  "<table width='100%'>"  
Add-Content $reportinativos  "<tr bgcolor='GainsBoro'>"  
Add-Content $reportinativos  "<td width='5%' align='center'><B>Servidor</B></td>"  
Add-Content $reportinativos  "<td width='10%' align='center'><B>Responde a ping?</B></td>"  
Add-Content $reportinativos  "<td width='10%' align='center'><B>Status do serviço Netlogon</B></td>"  
Add-Content $reportinativos  "<td width='10%' align='center'><B>Status do serviço NTDS</B></td>"  
Add-Content $reportinativos  "<td width='10%' align='center'><B>Status do serviço DNS</B></td>"  
Add-Content $reportinativos  "<td width='10%' align='center'><B>Acessa o Netlogon?</B></td>" 
Add-Content $reportinativos  "<td width='10%' align='center'><B>Está replicando?</B></td>" 
Add-Content $reportinativos  "<td width='10%' align='center'><B>Demais serviços relacionados estão rodando?</B></td>" 
  
Add-Content $reportinativos "</tr>"  
 
# Lista todos os DC's do domínio:
 
$getForest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest() 
 
$DCServers = $getForest.domains | ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name}  
 
# Teste de Ping
 
foreach ($DC in $DCServers){ 
$Servidor = $DC 
                Add-Content $reportinativos "<tr>" 
if ( Test-Connection -ComputerName $DC -Count 1 -ErrorAction SilentlyContinue ) { 
Write-Host $DC `t $DC `t Ping Success -ForegroundColor Green 
  
        Add-Content $reportinativos "<td bgcolor= 'GainsBoro' align=center>  <B> $Servidor</B></td>"  
                Add-Content $reportinativos "<td bgcolor= #7EDE00 align=center>  <B>Responde</B></td>"  
 
# Valida o serviço Netlogon:

        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "Netlogon" -ErrorAction SilentlyContinue} -ArgumentList $DC 
                wait-job $serviceStatus -timeout $espera 
                if($serviceStatus.state -like "Running") 
                { 
                 Write-Host $DC `t Netlogon Service TimeOut -ForegroundColor Yellow 
                 Add-Content $reportinativos "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
                 stop-job $serviceStatus 
                } 
                else 
                { 
                $serviceStatus1 = Receive-job $serviceStatus 
                 if ($serviceStatus1.status -eq "Running") { 
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green  
                $svcName = $serviceStatus1.name  
                $svcState = $serviceStatus1.status           
                Add-Content $reportinativos "<td bgcolor= #7EDE00 align=center><B>Rodando</B></td>"  
                  } 
                 else  
                  {  
                 Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red  
               $svcName = $serviceStatus1.name  
               $svcState = $serviceStatus1.status           
               Add-Content $reportinativos "<td bgcolor= 'Red' align=center><B>Parado</B></td>"  
                  }  
                } 

# Valida o serviço NTDS:

        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "NTDS" -ErrorAction SilentlyContinue} -ArgumentList $DC 
                wait-job $serviceStatus -timeout $espera 
                if($serviceStatus.state -like "Running") 
                { 
                 Write-Host $DC `t NTDS Service TimeOut -ForegroundColor Yellow 
                 Add-Content $reportinativos "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
                 stop-job $serviceStatus 
                } 
                else 
                { 
                $serviceStatus1 = Receive-job $serviceStatus 
                 if ($serviceStatus1.status -eq "Running") { 
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green  
                $svcName = $serviceStatus1.name  
                $svcState = $serviceStatus1.status           
                Add-Content $reportinativos "<td bgcolor= #7EDE00 align=center><B>Rodando</B></td>"  
                  } 
                 else  
                  {  
                 Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red  
               $svcName = $serviceStatus1.name  
               $svcState = $serviceStatus1.status           
               Add-Content $reportinativos "<td bgcolor= 'Red' align=center><B>Parado</B></td>"  
                  }  
                } 

# Valida o serviço DNS:

        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "DNS" -ErrorAction SilentlyContinue} -ArgumentList $DC 
                wait-job $serviceStatus -timeout $espera 
                if($serviceStatus.state -like "Running") 
                { 
                 Write-Host $DC `t DNS Server Service TimeOut -ForegroundColor Yellow 
                 Add-Content $reportinativos "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
                 stop-job $serviceStatus 
                } 
                else 
                { 
                $serviceStatus1 = Receive-job $serviceStatus 
                 if ($serviceStatus1.status -eq "Running") { 
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green  
                $svcName = $serviceStatus1.name  
                $svcState = $serviceStatus1.status           
                Add-Content $reportinativos "<td bgcolor= #7EDE00 align=center><B>Rodando</B></td>"  
                  } 
                 else  
                  {  
                 Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red  
               $svcName = $serviceStatus1.name  
               $svcState = $serviceStatus1.status           
               Add-Content $reportinativos "<td bgcolor= 'Red' align=center><B>Parado</B></td>"  
                  }  
                } 

# Testa o acesso ao NetLogon:
 
               add-type -AssemblyName microsoft.visualbasic  
               $cmp = "microsoft.visualbasic.strings" -as [type] 
               $sysvol = start-job -scriptblock {dcdiag /test:netlogons /s:$($args[0])} -ArgumentList $DC 
               wait-job $sysvol -timeout $espera 
               if($sysvol.state -like "Running") 
               { 
               Write-Host $DC `t Netlogons Test TimeOut -ForegroundColor Yellow 
               Add-Content $reportinativos "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
               stop-job $sysvol 
               } 
               else 
               { 
               $sysvol1 = Receive-job $sysvol 
               if($cmp::instr($sysvol1, "passed test NetLogons")) 
                  { 
                  Write-Host $DC `t Netlogons Test passed -ForegroundColor Green 
                  Add-Content $reportinativos "<td bgcolor= #7EDE00 align=center><B>Netlogon Acessível</B></td>" 
                  } 
               else 
                  { 
                  Write-Host $DC `t Netlogons Test Failed -ForegroundColor Red 
                  Add-Content $reportinativos "<td bgcolor= 'Red' align=center><B>Netlogon Inacessível</B></td>" 
                  } 
                } 

# Valida a replicação entre os servidores:
 
               add-type -AssemblyName microsoft.visualbasic  
               $cmp = "microsoft.visualbasic.strings" -as [type] 
               $sysvol = start-job -scriptblock {dcdiag /test:Replications /s:$($args[0])} -ArgumentList $DC 
               wait-job $sysvol -timeout $espera 
               if($sysvol.state -like "Running") 
               { 
               Write-Host $DC `t Replications Test TimeOut -ForegroundColor Yellow 
               Add-Content $reportinativos "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
               stop-job $sysvol 
               } 
               else 
               { 
               $sysvol1 = Receive-job $sysvol 
               if($cmp::instr($sysvol1, "passed test Replications")) 
                  { 
                  Write-Host $DC `t Replications Test passed -ForegroundColor Green 
                  Add-Content $reportinativos "<td bgcolor= #7EDE00 align=center><B>Sim</B></td>" 
                  } 
               else 
                  { 
                  Write-Host $DC `t Replications Test Failed -ForegroundColor Red 
                  Add-Content $reportinativos "<td bgcolor= 'Red' align=center><B>Não</B></td>" 
                  } 
                } 

# Valida o status dos serviços:

               add-type -AssemblyName microsoft.visualbasic  
               $cmp = "microsoft.visualbasic.strings" -as [type] 
               $sysvol = start-job -scriptblock {dcdiag /test:Services /s:$($args[0])} -ArgumentList $DC 
               wait-job $sysvol -timeout $espera 
               if($sysvol.state -like "Running") 
               { 
               Write-Host $DC `t Services Test TimeOut -ForegroundColor Yellow 
               Add-Content $reportinativos "<td bgcolor= 'Yellow' align=center><B>Não respondeu a tempo</B></td>" 
               stop-job $sysvol 
               } 
               else 
               { 
               $sysvol1 = Receive-job $sysvol 
               if($cmp::instr($sysvol1, "passed test Services")) 
                  { 
                  Write-Host $DC `t Services Test passed -ForegroundColor Green 
                  Add-Content $reportinativos "<td bgcolor= #7EDE00 align=center><B>Sim</B></td>" 
                  } 
               else 
                  { 
                  Write-Host $DC `t Services Test Failed -ForegroundColor Red 
                  Add-Content $reportinativos "<td bgcolor= 'Red' align=center><B>Não</B></td>" 
                  } 
                } 
                 
}  
else 
              { 
Write-Host $DC `t $DC `t Ping Fail -ForegroundColor Red 
        Add-Content $reportinativos "<td bgcolor= 'GainsBoro' align=center>  <B>$Servidor</B></td>"  
        Add-Content $reportinativos "<td bgcolor= 'Red' align=center>  <B>Falhou</B></td>"  
        Add-Content $reportinativos "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"  
        Add-Content $reportinativos "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"  
        Add-Content $reportinativos "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"  
        Add-Content $reportinativos "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
        Add-Content $reportinativos "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
        Add-Content $reportinativos "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
}          
        
}  
 
Add-Content $reportinativos "</tr>" 

# Fim do conteúdo HTML
 
Add-Content $reportinativos  "</table>"  
Add-Content $reportinativos "</body>"  
Add-Content $reportinativos "</html>"

######################################## DESCONSIDERAR POR HORA #########################################
# Envia o reporte por e-mail: 
# Parâmetros de E-mail (ainda em fase de testes)
#$servidorsmtp = 'smtp.office365.com'  
#$de = 'rotinas@eitisolucoes.com.br'
#$senhade = 'Dawo8383'
#Add-Type -AssemblyName Microsoft.VisualBasic
#$para = [Microsoft.VisualBasic.Interaction]::InputBox("Insira seu endereço de e-mail para receber o status da validação:", "[$dominio] Status da Saúde do AD", "email@dominio.com.br")
#$assunto = "[$dominio] Acompanhamento da Saúde do AD"  
#$mensagem = Get-Content "$reportesaudead" -Raw
#$username=$de
#$password=ConvertTo-SecureString "$senhade" -AsPlainText -Force
#$mycredentials = New-Object System.Management.Automation.PSCredential ($username, $password)
#Send-MailMessage -To "$para" -subject "$assunto" -body $mensagem -BodyAsHtml -Encoding utf8 -UseSsl -Port 587 -SmtpServer smtp.office365.com -From $username -Credential $mycredentials

cd ..

# Fim.