const ComposableParentERC721 = artifacts.require("ComposableParentERC721");
const ComposableChildrenERC1155 = artifacts.require("ComposableChildrenERC1155");
const web3 = require('web3');

contract("ComposableParentERC721", accounts => {
  let admin;
  let erc998;
  let erc1155;
  let composable1 = 1;
  let composable2 = 2;
  let multiTokenTier0 = 0;  //tier 0
  let multiTokenTier1 = 1;  //tier 1
  let multiTokenTier2 = 2;  //tier 2
  let user1 = accounts[1];
  let user2 = accounts[2];
  let tierUpgradeCost1 = 500;
  let tierUpgradeCost2 = 600;


//deploy contracts ERC998TDMP , ERC1155TUMP

  beforeEach (async () => {
    admin = accounts[0];
    erc998 = await  ComposableParentERC721.new("erc998", "ERC998", "https://ERC998.com/{id}",tierUpgradeCost1, { from: admin });
    erc1155 = await ComposableChildrenERC1155.new("https://ERC1155.com/{id}", erc998.address, { from: admin });

    await erc998.mint({ from: user1, value: web3.utils.toWei('2') });
    erc998.setTierUpgradeCost(multiTokenTier2,tierUpgradeCost2);
    // await erc1155.mint(user1,100);
    // await erc998.mint(user2, composable2, { from: admin });

  });

  it ("Verified ERC998, ERC1155TU", async() => {
    assert.equal(await erc998.name(),"erc998");
    console.log(erc998.address);

  });
  it ("erc998 : check state var", async() => {
    assert.equal(await erc998.name(),"erc998");
    console.log(erc998.address);

  });

// check if user csnft Balance
  it ("User1 has composable1", async() => {
    assert.equal((await erc998.balanceOf(user1)).toString() , (1).toString());
    // assert.equal(await erc998.balanceOf(user2),1);
  });
  
  it ("check 998 setters and getters", async() => {
    await erc998.setTierUpgradeCost(multiTokenTier1,tierUpgradeCost2);

    assert.equal((await erc998.getTierUpgradeCost(multiTokenTier1)).toString() , (tierUpgradeCost2).toString());
    // assert.equal(await erc998.balanceOf(user2),1);
  });
  
  it ("User1 has 500 engagement points", async() => {
    await erc1155.mintEngagementPoints(user1,500,"0x0", {from: user1});

    assert.equal((await erc1155.balanceOf(user1,0)).toString() , (500).toString());
    // assert.equal(await erc998.balanceOf(user2),1);
  });

  it ("Upgrade composable1", async() => {
    await erc1155.mintEngagementPoints(user1,500,"0x0");

    console.log(await erc1155.balanceOf(user1,0));
    await erc1155.upgradeSNFT(composable1, multiTokenTier1, web3.utils.encodePacked(composable1),{from:user1});
    res = await erc998.childBalance(composable1, erc1155.address, multiTokenTier1);
    assert.equal(res,1);
    tx = await erc998.childIdsForOn(composable1, erc1155.address);
    console.log(">>>>>>>>>>>>>>>>");
    console.log(tx);
    // console.log(">>>>>>>>>>>>>>>>");
    // console.log(await erc1155.balanceOf(user1,1));
  });

//handle recursive tier1 minting case 
  it("Composable 1 , receive upgrade to tier1 then tier2", async () => {
    await erc1155.mintEngagementPoints(user1,500,"0x0");

    await erc1155.upgradeSNFT(composable1, multiTokenTier1, web3.utils.encodePacked(composable1),{from:user1});

    assert.equal(await erc998.childBalance(composable1, erc1155.address, multiTokenTier1), 1);
    assert.equal(await erc998.getLevel(composable1, erc1155.address),1);
    // console.log(">>>>>>>>>>>>>>>>");
    // console.log(tx);
    await erc1155.mintEngagementPoints(user1,600,"0x0");
    await erc1155.upgradeSNFT(composable1, multiTokenTier2, web3.utils.encodePacked(composable1),{from:user1});

    // assert.equal(await erc998.childBalance(composable1, erc1155.address, multiTokenTier2),1);
    assert.equal(await erc998.getLevel(composable1, erc1155.address),2);
  });

});
