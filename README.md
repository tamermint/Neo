## Deep Learning Exploration

- Utilising Structured AI prompts to generate learning material and solidity projects

- Prompt

```
Let's discuss topics or concept based on the chats and my ideas, and you'll ask me questions to help me explore them further. We'll work together to build a deep understanding of each topic, and you'll provide feedback to help me identify any misconceptions or gaps in my understanding, sort of like the Feynman technique. We'll approach this with an open mind, and we'll be curious and inquisitive as we explore the topic. Also start with prescribing small mini coding projects and also include design questions. Gradually increase complexity of the projects.

I want you to keep in mind that you do also ask specific questions that will push my understanding of said topic, it doesn't matter if I'm not capable of answering cause my goal is to learn more and more. I wish to use the ultra learning approach. Let's begin.
```

- Topics getting covered - Asset Allocation, Log returns calculation and solidity PoC

## Progress Update

- Python Script Created to get asset history using yfinance lib. Rolling mean and log percent calculated to check whether closing price of an asset deviates more than 0.19% in a year :

  ```py
  ticker = ["BIL",'SHY']
  history = yf.download(ticker, start='2025-01-01', group_by='ticker', multi_level_index=True, keepna=False)
  change = history.pct_change() * 100
  backfilled_change = change.ffill().dropna().round(4).swaplevel(0, 1, axis=1)
  backfilled_change.rename_axis(["Change %", "Ticker"], axis=1, inplace=True)
  breachSHY = 0
  breachBIL = 0
  mostRecentBreachDate = ""
  def breach_count(breacharr):
  breachCount = 0
  for i in breacharr:
  if i > 0.19:
  breachCount +=1

        return breachCount

        breachSHY = breach_count(backfilled_change['Close']['SHY'])
        breachBIL = breach_count(backfilled_change['Close']['BIL'])

        shy_df = pd.DataFrame(backfilled_change['Close']['SHY'])
        shy_df = shy_df[shy_df['SHY'] > 0.19]

        bil_df = pd.DataFrame(backfilled_change['Close']['BIL'])
        bil_df = bil_df[bil_df['BIL'] > 0.19]

        mostRecentBreachDate_BIL = bil_df.index.max().date()
        mostRecentBreachDate_SHY = shy_df.index.max().date()

        if pd.isnull(mostRecentBreachDate_SHY):
        mostRecentBreachDate_SHY = "No breach"
        if pd.isnull(mostRecentBreachDate_BIL):
        mostRecentBreachDate_BIL = "No breach"

        shydf_all = backfilled_change['Close']['SHY']

      bildf_all = backfilled_change['Close']['BIL']
      shydf_all = np.log1p(shydf_all).dropna().round(5)
      bildf_all = np.log1p(bildf_all).dropna().round(5)
      shydfall_logadj = shydf_all.rolling(30).std().dropna().round(5)
      bildfall_logadj = bildf_all.rolling(30).std().dropna().round(5)
      shy_std = shydfall_logadj.std()
      bil_std = bildfall_logadj.std()
      shystd_rounded = round(shy_std, 5)
      bilstd_rounded = round(bil_std, 5)
      shy_annvolatility = round((shystd_rounded _ np.sqrt(252)), 5)
      bil_annvolatility = round((bilstd_rounded _ np.sqrt(252)), 5)
      #print(shy_annvolatility)
      #print(bil_annvolatility)

      # trim proportional to sigma

      excess = max(0, ((shy_annvolatility - 0.19)/0.19))
      print(excess)

      table = [
      ["SHY", breachSHY, mostRecentBreachDate_SHY, shy_annvolatility],
      ["BIL", breachBIL, mostRecentBreachDate_BIL, bil_annvolatility],
      ]
      print('\n')
      print(tabulate(table, headers=["Ticker", "Breach Count", "Most Recent breach", "Annualized Volatility"]))

  ```

- Solidity PoC written that updates allocation based on sigma of crypto assets (sigma is volatility)

  ```solidity
    function trim(uint256 assetSigma, uint256 assetAllocation, uint256 trimpp) public onlyOwner {
        if (assetSigma < i_CAP) {
            revert Neo__AssetSigmaIsBelow20PP();
        }
        if (lastTrimBlock >= block.number) {
            revert Neo__CannotTrimTwiceInSingleBlock();
        }
        if (assetSigma >= i_CAP && lastTrimBlock < block.number) {
            updateAllocation(assetAllocation, trimpp);
            emit VolTrim("Trimmed", assetAllocation, assetSigma);
            lastTrimBlock = block.number;
        }
        lastTrimBlock = block.number;
    }
  ```

- Minimalist Vault created with ERC4626 standard :

```solidity
  constructor(IERC20 asset_) ERC20("ESF Vault Share", "ESFV") ERC4626(asset_) Ownable(msg.sender) {}

    //FUNCTIONS

    function depositAsset(uint256 assets, address receiver) public nonReentrant {
        if (assets == 0) {
            revert ESF__CannotDepositZero();
        }
        if (receiver == address(0)) {
            revert ESF__ReceiverCantBeZeroAddress();
        }
        deposit(assets, receiver);
    }

    function requestWithdrawal(uint256 shares) public returns (bool passed) {
        //who calls this function must have the mapping updated
        lastWithdrawRequest[msg.sender].timestamp = block.timestamp;
        lastWithdrawRequest[msg.sender].shares = shares;
        emit WithdrawRequested(msg.sender, shares);
        return true;
    }

    function fulfillWithdrawal(uint256 shares, address requestor) public nonReentrant {
        checkWithdrawalAndVaultConditions(shares, requestor);
        if (block.timestamp - lastWithdrawRequest[requestor].timestamp <= 172800 seconds) {
            emit EmergencyWithdrawalInitiated(requestor, shares);
        }
        redeem(shares, requestor, requestor);
        emit WithdrawalFulfilled(msg.sender, requestor, shares);
        lastWithdrawRequest[requestor].timestamp = 0;
        lastWithdrawRequest[msg.sender].shares = 0;
    }

    function checkWithdrawalAndVaultConditions(uint256 shares, address requestor) public {
        if (totalSupply() == 0) {
            revert ESF__VaultIsEmpty();
        }

        if (block.timestamp - lastWithdrawRequest[requestor].timestamp < 86400 seconds) {
            revert ESF__CannotWithdrawWithin24Hrs();
        }
        if (checkVaultHealthRatioBeforeWithdraw() == false) {
            emit TemporaryWithdrawalHold(block.timestamp);
        }
        if (checkHealthRatioAfterWithdraw(shares) == false) {
            emit VaultSolvencyCheckBreached(shares, block.timestamp);
        }
    }

    function checkVaultHealthRatioBeforeWithdraw() public view returns (bool passed) {
        uint256 totalAssets = totalAssets();
        uint256 totalShares = totalSupply();
        return FixedPointMathLib.divWadDown(totalAssets, totalShares) > HBR ? true : false;
    }

    function checkHealthRatioAfterWithdraw(uint256 shares) public view returns (bool passed) {
        //simulate withdrawal
        //preview redeem
        uint256 assets = previewRedeem(shares);
        //preview assets
        uint256 remainingAssets = totalAssets() - assets;
        uint256 remainingShares = totalSupply() - shares;
        //return HBR
        return FixedPointMathLib.divWadDown(remainingAssets, remainingShares) > HBR ? true : false;
    }

```
