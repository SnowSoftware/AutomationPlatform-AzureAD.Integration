$moduleRoot = Resolve-Path "$PSScriptRoot\..\Snow.SnowAutomationPlatform.AzureAD.Integration"
$moduleName = Split-Path $moduleRoot -Leaf

Describe "General project validation: $moduleName" { 

    $scripts = Get-ChildItem $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse

    # TestCases are splatted to the script so we need hashtables
    $testCase = $scripts | ForEach-Object { @{file = $_}}         
    It "Script <file> should be valid powershell" -TestCases $testCase { 
        param($file)

        $file.fullname | Should Exist

        $contents = Get-Content -Path $file.fullname -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
        $errors.Count | Should Be 0
    }

    It "Module '$moduleName' can import cleanly" { 
        { Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -Force } | Should Not Throw
    }
}


InModuleScope $moduleName { 
    Describe 'Connect-APAzureADAccount' { 
        Context 'Successfull logins' { 
            Mock -CommandName Connect-AzureAD -MockWith { 
                $account = [Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount]::new()
                $account.Id = 'FakeAccount@FakeAccount.onmicrosoft.com'
                $account.Type = 'User'
                $Envi = [Microsoft.Open.Azure.AD.CommonLibrary.AzureEnvironment]::new()
                $Envi.Name = 'AzureCloud'

                $ret = New-Object -TypeName psobject -Property @{
                    'Account' = $account
                    'AccountType' = [string]'User'
                    'Environment' = $Envi
                    'TenantDomain' = [string]'FakeAccount.onmicrosoft.com'
                    'TenantID' = @(New-Guid)
                }  
                return $ret
            }
            
            # Build a fake credential object to use, and log it in
            [SecureString]$securePassword = ConvertTo-SecureString 'FakePassword' -AsPlainText -Force
            [PSCredential]$Creds = New-Object Management.Automation.PSCredential ('FakeAccount@FakeAccount.onmicrosoft.com', $securePassword)
            $Login = $null
            $Login = Connect-APAzureADAccount -Credential $Creds

            It 'Login Object should exist' { 
                $Login | Should -Not -BeNullOrEmpty
            }
            It 'Login should have five properties set' { 
                # Since we mock Connect-AzureAD the membertypes will be noteproperty, where as it should be property if Connect-AzureAD was not mocked.
                $MemberCount = ($Login | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name).Count
                $MemberCount | Should -Be 5
            }
            It 'Account Should match FakeLogin' { 
                $Login.Account | Should -BeOfType Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount
                $Login.Account.Id | Should -BeExactly 'FakeAccount@FakeAccount.onmicrosoft.com'
            }
            It 'AccountType Should be User' { 
                $Login.AccountType | Should -BeOfType String
                $Login.Account.Type | Should -BeExactly 'User'
            }
            It 'Environment Should be AzureCloud' { 
                $Login.Environment | Should -BeOfType Microsoft.Open.Azure.AD.CommonLibrary.AzureEnvironment
                $Login.Environment.Name | Should -BeExactly 'AzureCloud'
            }
            It 'TenantDomain Should match FakeLogin domain' { 
                $Login.TenantDomain | Should -BeOfType String
                $Login.TenantDomain | Should -BeExactly 'FakeAccount.onmicrosoft.com'
            }
            It 'TenantId Should match guid' { 
                $Login.TenantId | Should -BeOfType System.Guid
                $Login.TenantId.Guid | Should -Match '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'
            }
            It 'Should have mocked ConnectAzureAD' { 
                Assert-MockCalled -CommandName Connect-AzureAD -Exactly 1 -Scope Context
            }
        }

        Context 'Unsuccessfull logins' { 
            Mock -CommandName Connect-AzureAD -MockWith { Throw 'I´m a mock!'}

            # Build a fake credential object to use, and remove login variable
            [SecureString]$securePassword = ConvertTo-SecureString 'FailPassword' -AsPlainText -Force
            [PSCredential]$Creds = New-Object Management.Automation.PSCredential ('FailAccount@FailAccount.onmicrosoft.com', $securePassword)
            Remove-Variable Login -ErrorAction SilentlyContinue

            It 'Should throw if something fails during connection' { 
                { Connect-APAzureADAccount -Credential $Creds -ErrorVariable a -ErrorAction SilentlyContinue} | Should -Throw
            }
            It 'Should have mocked ConnectAzureAD' { 
                Assert-MockCalled -CommandName Connect-AzureAD -Exactly 1 -Scope Context
            }
        }
    }

    Describe 'Disconnect-APAzureADAccount' { 
        Context 'Sucessfull disconnection' { 
            Mock -CommandName Disconnect-AzureAD -MockWith { return $null}
            Mock -CommandName Get-AzureADTenantDetail -MockWith { Write-Error 'I´m a mock!'}
            
            It 'should return string' { 
                $State = Disconnect-APAzureADAccount -ErrorVariable a  -ErrorAction SilentlyContinue
                $State | Should -BeOfType String
                $State | Should -Be 'Disconnected all active Azure sessions'
            }
            
            It 'Should have called the Disconnect-AzureAD mock once' { 
                Assert-MockCalled -CommandName Disconnect-AzureAD -Exactly 1 -Scope Context
            }
            It 'Should have called the Get-AzureADTenantDetail mock once' { 
                Assert-MockCalled -CommandName Get-AzureADTenantDetail -Exactly 1 -Scope Context
            }
        }
        
        Context 'Unsucessfull disconnection' { 
            Mock -CommandName Disconnect-AzureAD -MockWith { return $null}
            Mock -CommandName Get-AzureADTenantDetail -MockWith { return $true}

            It 'should write error' { 
                # Since we want to capture the error stream we redirect it and test the error itself
                $State = Disconnect-APAzureADAccount -ErrorVariable a -ErrorAction SilentlyContinue
                $a.Exception.Message | Should -Be 'Failed to disconnect Azure sessions'
            }
            
            It 'Should have called the Disconnect-AzureAD mock once' { 
                Assert-MockCalled -CommandName Disconnect-AzureAD -Exactly 1 -Scope Context
            }
            It 'Should have called the Get-AzureADTenantDetail mock once' { 
                Assert-MockCalled -CommandName Get-AzureADTenantDetail -Exactly 1 -Scope Context
            }
        }
    }

    Describe 'New-APAzureADLicenseObject' { 
        Context 'Create object successfully' { 
            It 'Should return an empty license object' { 
                $a = New-APAzureAdLicenseObject
                $a | Should -BeOfType Microsoft.Open.AzureAD.Model.AssignedLicense
                $a.DisabledPlans | Should -BeNullOrEmpty
                $a.SkuId | Should -BeNullOrEmpty
            }

            It 'Should work with a single SkuId' { 
                $SkuId = (New-Guid).ToString()

                $a = New-APAzureAdLicenseObject -SkuId $SkuId 
                $a | Should -BeOfType Microsoft.Open.AzureAD.Model.AssignedLicense
                $a.DisabledPlans | Should -BeNullOrEmpty
                $a.SkuId | Should -Be $SkuId 
            }

            It 'Should work with a single SkuId and single disabled plan' { 
                $SkuId = (New-Guid).ToString()
                $Disabled = (New-Guid).ToString()

                $a = New-APAzureAdLicenseObject -SkuId $SkuId  -DisabledPlans $Disabled
                $a | Should -BeOfType Microsoft.Open.AzureAD.Model.AssignedLicense
                $a.DisabledPlans | Should -Be $Disabled
                $a.SkuId | Should -Be $SkuId 
            }
            It 'Should work with a single SkuId and multiple disabled plans' { 
                $SkuId = (New-Guid).ToString()
                $Disabled1 = (New-Guid).ToString()
                $Disabled2 = (New-Guid).ToString()
                $Disabled3 = (New-Guid).ToString()

                $a = New-APAzureAdLicenseObject -SkuId $SkuId  -DisabledPlans $Disabled1,$Disabled2,$Disabled3
                $a | Should -BeOfType Microsoft.Open.AzureAD.Model.AssignedLicense
                $Disabled1 | Should -BeIn $a.DisabledPlans
                $Disabled2 | Should -BeIn $a.DisabledPlans
                $Disabled3 | Should -BeIn $a.DisabledPlans
                $a.SkuId | Should -Be $SkuId 
            }
        }

        Context 'Fail to create license object' { 
            It 'Should throw if failed to load .net class' { 
                Mock -CommandName New-Object -ParameterFilter { $TypeName -eq 'Microsoft.Open.AzureAD.Model.AssignedLicense'} -MockWith { 
                    Throw 'Unable to find type'
                }

                { New-APAzureAdLicenseObject} | Should -Throw
                Assert-MockCalled -CommandName New-Object -Exactly 1 -ParameterFilter { $TypeName -eq 'Microsoft.Open.AzureAD.Model.AssignedLicense'} -Scope it
            }
            It 'Should throw if more than one SkuId is set' { 
                [String[]]$SkuId = @()
                $SkuId += (New-Guid).ToString()
                $SkuId += (New-Guid).ToString()

                { New-APAzureAdLicenseObject -SkuId $SkuId} | Should -Throw
            }

            It 'Should throw if SkuId is not a valid Guid' { 
                { New-APAzureAdLicenseObject -SkuId 'Not a guid!'} | Should -Throw
            }
            It 'Should throw if Disabled plan is not a valid Guid, single object' { 
                $SkuId = (New-Guid).ToString()

                { New-APAzureAdLicenseObject -SkuId $SkuId -DisabledPlans 'Not a guid!'} | Should -Throw
            }
            It 'Should throw if Disabled plan is not a valid Guid, multiple objects' { 
                $SkuId = (New-Guid).ToString()
                $Disabled1 = (New-Guid).ToString()
                $Disabled2 = (New-Guid).ToString()
                $Disabled3 = 'Not a guid!'

                { New-APAzureAdLicenseObject -SkuId $SkuId -DisabledPlans $Disabled1,$Disabled2,$Disabled3} | Should -Throw
            }
            It 'Should throw if Disabled plan is set without SkuId' { 
                $Disabled = (New-Guid).ToString()

                { New-APAzureAdLicenseObject -DisabledPlans $Disabled} | Should -Throw
            }
        }
    }

    Describe 'New-APAzureADLicensesObject' { 
        Context 'Create object successfully' { 
            $LicGuid1 = (New-Guid).ToString()
            $LicGuid2 = (New-Guid).ToString()
            $LicGuid3 = (New-Guid).ToString()
            $lic1 = New-APAzureAdLicenseObject -SkuId $LicGuid1
            $lic2 = New-APAzureAdLicenseObject -SkuId $LicGuid1
            $lic3 = New-APAzureAdLicenseObject -SkuId $LicGuid1
            
            It 'Should work with no parameters set' { 
                $a = New-APAzureAdLicensesObject
                $a.AddLicenses | Should -BeNullOrEmpty
                $a.RemoveLicenses | Should -BeNullOrEmpty
            }
            It 'Should work with adding one license object' { 
                $a = New-APAzureAdLicensesObject -AddLicenses $lic1
                $a | Should -BeOfType Microsoft.Open.AzureAD.Model.AssignedLicenses
                $a.AddLicenses.SkuId | Should -Be $LicGuid1
            }
            It 'Should work with adding more license objects' { 
                $a = New-APAzureAdLicensesObject -AddLicenses $lic1,$lic2,$lic3
                $a | Should -BeOfType Microsoft.Open.AzureAD.Model.AssignedLicenses
                $a.AddLicenses.SkuId[0] | Should -Be $LicGuid1
                $a.AddLicenses.SkuId[1] | Should -Be $LicGuid1
                $a.AddLicenses.SkuId[2] | Should -Be $LicGuid1
                $a.AddLicenses.SkuId.Count | Should -Be 3
            }
            It 'Should work with adding and removing single licenses' { 
                $a = New-APAzureAdLicensesObject -AddLicenses $lic1 -RemoveLicenses $LicGuid1
                $a.AddLicenses.SkuId | Should -Be $LicGuid1
                
                $a.RemoveLicenses | Should -Be $LicGuid1
                $a.RemoveLicenses[0] | Should -BeOfType String
            }
            It 'Should work with adding and removing multiple licenses' { 
                $a = New-APAzureAdLicensesObject -AddLicenses $lic1,$lic2 -RemoveLicenses $LicGuid1,$LicGuid2,$LicGuid3
                $a.AddLicenses.SkuId[0] | Should -Be $LicGuid1
                $a.AddLicenses.SkuId[1] | Should -Be $LicGuid1
                $a.AddLicenses.SkuId.Count | Should -Be 2

                $a.RemoveLicenses[0] | Should -Be $LicGuid1
                $a.RemoveLicenses[1] | Should -Be $LicGuid2
                $a.RemoveLicenses[2] | Should -Be $LicGuid3
                $a.RemoveLicenses[0] | Should -BeOfType String
                $a.RemoveLicenses.Count | Should -Be 3
            }
            It 'Should work with only removing single licenses' { 
                $a = New-APAzureAdLicensesObject -RemoveLicenses $LicGuid1
                $a.RemoveLicenses[0] | Should -Be $LicGuid1
                $a.RemoveLicenses.Count | Should -Be 1
            }
            It 'Should work with only removing multiple licenses' { 
                $a = New-APAzureAdLicensesObject -RemoveLicenses $LicGuid1,$LicGuid2,$LicGuid3
                $a.RemoveLicenses[0] | Should -Be $LicGuid1
                $a.RemoveLicenses[1] | Should -Be $LicGuid2
                $a.RemoveLicenses[2] | Should -Be $LicGuid3
                $a.RemoveLicenses[0] | Should -BeOfType String
                $a.RemoveLicenses.Count | Should -Be 3
            }
        }

        Context 'Failed to create Licenses object' { 
            $LicGuid1 = (New-Guid).ToString()
            $LicGuid2 = (New-Guid).ToString()
            $LicGuid3 = (New-Guid).ToString()
            $lic1 = New-APAzureAdLicenseObject -SkuId $LicGuid1
            $lic2 = New-APAzureAdLicenseObject -SkuId $LicGuid1
            $lic3 = New-APAzureAdLicenseObject -SkuId $LicGuid1
            
            It 'Should throw if failed to load .net class' { 
                Mock -CommandName New-Object -MockWith { 
                    Throw 'Unable to find type'
                }
                { New-APAzureAdLicensesObject} | Should -Throw
                Assert-MockCalled -CommandName New-Object -Exactly 1 -Scope it 
            }
            It 'Should throw if RemoveLicenses is not a valid Guid, Single object' { 
                { New-APAzureAdLicensesObject -RemoveLicenses 'NotAGuid'} | Should -Throw
            }
            It 'Should throw if RemoveLicenses is not a valid Guid, Multiple objects' { 
                { New-APAzureAdLicensesObject -RemoveLicenses $LicGuid1,$LicGuid2,'NotAGuid'} | Should -Throw
            }
            It 'Should throw if AddLicenses is not valid type, Single license' { 
                { New-APAzureAdLicensesObject -AddLicenses 'NotALicense'} | Should -Throw
            }
            It 'Should throw if AddLicenses is not valid type, Multiple license' { 
                { New-APAzureAdLicensesObject -AddLicenses $lic1,$lic2,'NotALicense'} | Should -Throw
            }
        }
    }

    Describe 'Get-APAzureADUser' { 
        Context 'Account exists' { 
            Mock  -Verifiable -CommandName Get-AzureADUser -MockWith { 
                $ret = [Microsoft.Open.AzureAD.Model.User]::new(
                    [bool]$true,
                    [string]'City',
                    [string]'Country',
                    [string]'CreationType',
                    [string]'Department',
                    [string]'DisplayName',
                    [string]'FacsimileTelephoneNumber',
                    [string]'GivenName',
                    [bool]$true,
                    [string]'ImmutableId',
                    [string]'JobTitle',
                    [string]'MailNickName',
                    [string]'Mobile',
                    [System.Collections.Generic.List[string]]'OtherMails',
                    [string]'PasswordPolicies',
                    [Microsoft.Open.AzureAD.Model.PasswordProfile]::New(),
                    [string]'PhysicalDeliveryOfficeName',
                    [string]'PostalCode',
                    [string]'PreferredLanguage',
                    [bool]$true,
                    [System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.SignInName]]([Microsoft.Open.AzureAD.Model.SignInName]::new('Type','Value')),
                    [string]'State',
                    [string]'StreetAddress',
                    [string]'Surname',
                    [string]'TelephoneNumber',
                    [string]'UsageLocation',
                    [string]'UserPrincipalName',
                    [string]'UserType'
                ) 
                return $ret
            }
    
            It 'Should return a valid user when using searchstring (DisplayName)' { 
                $a = Get-APAzureADUser -SearchString 'DisplayName'
                $a.DisplayName | Should -Be 'DisplayName'
                $a.AccountEnabled | Should -Be $true
            }
            It 'Should return a valid user when using ObjectId' { 
                $a = Get-APAzureADUser -ObjectId '562e2821-9a56-4904-995a-debf4673f65c'
                $a.DisplayName | Should -Be 'DisplayName'
                $a.AccountEnabled | Should -Be $true
            }
            It 'Should return a valid user when using Filter' { 
                # For detail on filter parameter, see https://docs.microsoft.com/en-us/powershell/module/azuread/get-azureaduser?view=azureadps-2.0 and http://www.odata.org/documentation/odata-version-3-0/odata-version-3-0-core-protocol/#queryingcollections
                $a = Get-APAzureADUser -Filter "DisplayName eq 'FakeUser'"
                $a.DisplayName | Should -Be 'DisplayName'
                $a.AccountEnabled | Should -Be $true
            }
            It 'Should return a valid user when using All switch' { 
                $a = Get-APAzureADUser -All
                $a.DisplayName | Should -Be 'DisplayName'
                $a.AccountEnabled | Should -Be $true
            }
            It 'Should return a valid user and use the "All" ParameterSet when using no params' { 
                $a = Get-APAzureADUser
                $a.DisplayName | Should -Be 'DisplayName'
                $a.AccountEnabled | Should -Be $true
            }
            It 'Should have called mock 5 times' { 
                Assert-MockCalled -CommandName Get-AzureADUser -Exactly 5 -Scope Context
            }
        }
        
        Context 'Multiple accounts exists' { 
            Mock  -Verifiable -CommandName Get-AzureADUser -MockWith { 
                $ret = @()
                $ret += [Microsoft.Open.AzureAD.Model.User]::new(
                    [bool]$true,
                    [string]'City',
                    [string]'Country',
                    [string]'CreationType',
                    [string]'Department',
                    [string]'DisplayName',
                    [string]'FacsimileTelephoneNumber',
                    [string]'GivenName',
                    [bool]$true,
                    [string]'ImmutableId',
                    [string]'JobTitle',
                    [string]'MailNickName',
                    [string]'Mobile',
                    [System.Collections.Generic.List[string]]'OtherMails',
                    [string]'PasswordPolicies',
                    [Microsoft.Open.AzureAD.Model.PasswordProfile]::New(),
                    [string]'PhysicalDeliveryOfficeName',
                    [string]'PostalCode',
                    [string]'PreferredLanguage',
                    [bool]$true,
                    [System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.SignInName]]([Microsoft.Open.AzureAD.Model.SignInName]::new('Type','Value')),
                    [string]'State',
                    [string]'StreetAddress',
                    [string]'Surname',
                    [string]'TelephoneNumber',
                    [string]'UsageLocation',
                    [string]'UserPrincipalName',
                    [string]'UserType'
                ) 
                $ret += [Microsoft.Open.AzureAD.Model.User]::new(
                    [bool]$true,
                    [string]'City',
                    [string]'Country',
                    [string]'CreationType',
                    [string]'Department',
                    [string]'DisplayName',
                    [string]'FacsimileTelephoneNumber',
                    [string]'GivenName',
                    [bool]$true,
                    [string]'ImmutableId',
                    [string]'JobTitle',
                    [string]'MailNickName',
                    [string]'Mobile',
                    [System.Collections.Generic.List[string]]'OtherMails',
                    [string]'PasswordPolicies',
                    [Microsoft.Open.AzureAD.Model.PasswordProfile]::New(),
                    [string]'PhysicalDeliveryOfficeName',
                    [string]'PostalCode',
                    [string]'PreferredLanguage',
                    [bool]$true,
                    [System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.SignInName]]([Microsoft.Open.AzureAD.Model.SignInName]::new('Type','Value')),
                    [string]'State',
                    [string]'StreetAddress',
                    [string]'Surname',
                    [string]'TelephoneNumber',
                    [string]'UsageLocation',
                    [string]'UserPrincipalName',
                    [string]'UserType'
                )
                return $ret
            }

            It 'Should return an array of users if many objects are returned' { 
                $a = Get-APAzureADUser -All
                $a.Count | Should -Be 2
            }

            It 'Should have called mock 1 times' { 
                Assert-MockCalled -CommandName Get-AzureADUser -Exactly 1 -Scope Context
            }
        }
        
        Context 'Account does not exist, or failed search' { 
            Mock  -Verifiable -CommandName Get-AzureADUser -MockWith { 
                $ret = [Microsoft.Open.AzureAD.Model.User]::new(
                    [bool]$true,
                    [string]'City',
                    [string]'Country',
                    [string]'CreationType',
                    [string]'Department',
                    [string]'DisplayName',
                    [string]'FacsimileTelephoneNumber',
                    [string]'GivenName',
                    [bool]$true,
                    [string]'ImmutableId',
                    [string]'JobTitle',
                    [string]'MailNickName',
                    [string]'Mobile',
                    [System.Collections.Generic.List[string]]'OtherMails',
                    [string]'PasswordPolicies',
                    [Microsoft.Open.AzureAD.Model.PasswordProfile]::New(),
                    [string]'PhysicalDeliveryOfficeName',
                    [string]'PostalCode',
                    [string]'PreferredLanguage',
                    [bool]$true,
                    [System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.SignInName]]([Microsoft.Open.AzureAD.Model.SignInName]::new('Type','Value')),
                    [string]'State',
                    [string]'StreetAddress',
                    [string]'Surname',
                    [string]'TelephoneNumber',
                    [string]'UsageLocation',
                    [string]'UserPrincipalName',
                    [string]'UserType'
                ) 
                return $ret
            }
            
            It 'Should Throw when more than one parameter is used, except -all' { 
                { Get-APAzureADUser -SearchString 'Fail' -ObjectId 'Fail'} | Should -Throw
                { Get-APAzureADUser -SearchString 'Fail' -Filter 'Fail'}  | Should -Throw
                { Get-APAzureADUser -Filter 'Fail' -ObjectId 'Fail'} | Should -Throw
            }

            It 'Should throw if ObjectId is not a valid Guid' { 
                { Get-APAzureADUser -ObjectId 'NotAGuid'} | Should -Throw
            }

            # This test will not work with mock.
            It 'Should throw if filter is not a valid OData object' -Skip { 
                Get-APAzureADUser -Filter 'NotAOdataObject' | Should -Throw
            }

            # This test will not work with mock.
            It 'Should return null results when no user is found' -Skip { 
                $a = Get-APAzureADUser -Filter "DisplayName eq 'NotAUser'"
                $a | Should -BeNullOrEmpty
            }

            It 'Should return error if request fails' { 
                Mock -CommandName Get-AzureADUser -MockWith { 
                    Throw 'Fail'
                }
                $output = Get-APAzureADUser -SearchString 'Anything' -ErrorVariable a -ErrorAction SilentlyContinue
                $a.Exception.Message | Should -Not -BeNullOrEmpty
            }

            It 'Should have called mock 1 times' { 
                Assert-MockCalled -CommandName Get-AzureADUser -Exactly 1 -Scope Context
            }
        }
    }

    Describe 'Get-APAzureADUserLicense' { 
        Context 'Successfully got a license' { 
            Mock Get-AzureADUserLicenseDetail -MockWith { 
                $ret = @()
                $ret += [Microsoft.Open.AzureAD.Model.ServicePlanInfo]::new(
                    'Company1',
                    'Success',
                    '40f6646b-05ec-4f8e-9c8c-a07f3b407146',
                    'FAKE_SERVICEPLAN_NAME'
                )
                $ret += [Microsoft.Open.AzureAD.Model.ServicePlanInfo]::new(
                    'Company2',
                    'Success',
                    '906f2ccc-2ee6-4ec0-a6a1-0d91bbe88768',
                    'FAKE_SERVICEPLAN_NAME2'
                )
                Return $ret
            }

            It 'Should return a license object' { 
                $a = Get-APAzureADUserLicense -ObjectId ((New-Guid).ToString())
                $a[0].ServicePlanName | Should -Be 'FAKE_SERVICEPLAN_NAME'
            }

            It 'Should have called mock 1 times' { 
                Assert-MockCalled -CommandName Get-AzureADUserLicenseDetail -Exactly 1 -Scope Context
            }
        }

        Context 'Failed to get user license, or license is empty' { 
            It 'Should throw if Object is not a valid GUID' { 
                { Get-APAzureADUserLicense -ObjectId 'NotAGuid'} | Should -Throw
            }
            It 'Should return null if no valid license is found' { 
                Mock Get-AzureADUserLicenseDetail -MockWith { 
                    return $null
                }

                $a = Get-APAzureADUserLicense -ObjectId (New-Guid) 
                $a | Should -BeNullOrEmpty
                Assert-MockCalled -CommandName Get-AzureADUserLicenseDetail -Exactly 1 -Scope it
            }

            It 'Should return error when failing to get license' { 
                Mock Get-AzureADUserLicenseDetail -MockWith { 
                    Throw 'Error'
                }

                $a = Get-APAzureADUserLicense -ObjectId (New-Guid) -ErrorVariable err -ErrorAction SilentlyContinue
                $err.Exception.Message | Should -Not -BeNullOrEmpty
                Assert-MockCalled -CommandName Get-AzureADUserLicenseDetail -Exactly 1 -Scope it
            }
        }
    
    }

    Describe 'Set-APAzureADUserLicense' { 
        Context 'Successfully set license' { 
            $SkuId = (New-Guid).ToString()
            $LicenseObj = New-APAzureAdLicenseObject -SkuId $SkuId 
            $Licenses = New-APAzureAdLicensesObject -AddLicenses $LicenseObj
            
            Mock -CommandName Set-AzureADUserLicense -MockWith { 
                Return $null
            }

            It 'Should update a user license' { 
                $a = Set-APAzureADUserLicense -ObjectId (New-Guid) -AssignedLicenses $Licenses -ErrorVariable err
                $a | Should -BeNullOrEmpty
                $err | Should -BeNullOrEmpty
            }

            It 'Should have called the mock one time' { 
                Assert-MockCalled -CommandName Set-AzureADUserLicense -Exactly 1 -Scope Context
            }
        }

        Context 'Unsuccessfully set license' { 
            $SkuId = (New-Guid).ToString()
            $LicenseObj = New-APAzureAdLicenseObject -SkuId $SkuId 
            $Licenses = New-APAzureAdLicensesObject -AddLicenses $LicenseObj

            Mock -CommandName Set-AzureADUserLicense -MockWith { 
                Throw 'Not A Valid License'
            }

            It 'Should throw if license is not of type Microsoft.Open.AzureAD.Model.AssignedLicenses' { 
                { Set-APAzureADUserLicense -ObjectId (New-Guid)  -AssignedLicenses 'NotALicense'} | Should -Throw
            }
            It 'Should throw if no valid license is sent' { 
                { Set-APAzureADUserLicense -ObjectId (New-Guid)  -AssignedLicenses $Licenses} | Should -Throw
            }
            It 'Should throw if ObjectId is not a valid Guid' { 
                { Set-APAzureADUserLicense -ObjectId 'NotAGuid'  -AssignedLicenses $Licenses} | Should -Throw
            }
            It 'Should throw if more than one ObjectId is sent' { 
                { Set-APAzureADUserLicense -ObjectId (New-Guid),'NotAGuid'  -AssignedLicenses $Licenses} | Should -Throw
            }
            It 'Should have called the mock one time' { 
                Assert-MockCalled -CommandName Set-AzureADUserLicense -Exactly 1 -Scope Context
            }
        }
    }

}



