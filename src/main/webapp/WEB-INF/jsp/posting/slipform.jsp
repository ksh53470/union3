?<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %> <!-- JSTL을 사용하기 위해 커스텀 액션을 사용하겠다 라고 선언하는 것 -->
<!DOCTYPE html>
<html lang="en">

<head>
    <!--aggrid를 쓰기 위한 소스-->
    <script src="https://unpkg.com/ag-grid-community/dist/ag-grid-community.min.noStyle.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/ag-grid-community/dist/styles/ag-grid.css">
    <link rel="stylesheet" href="https://unpkg.com/ag-grid-community/dist/styles/ag-theme-balham.css">

    <%--jquery를 쓰기 위한 소스--%>
    <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
    <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>
    <link rel="stylesheet" href="//code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css">
    <title>메인</title>
    <!-- css를 안에 넣어둠 -->
    <!-- em단위는 부모 요소의 글꼴 크기를 말함, 0.9는 배율 -->
    <!-- css는 같은 속성을 여러번 정의했을 때. 나중에 설정한 값이 적용됩니다. 하지만 나중에 설정한 값이 적용되지 않게 하려면 속성값 뒤에 !important를 붙임 -->
    <!-- \f11f 이런것들은 전부다 직사각형 모양의 그림들임, 다 비슷비슷함 거의 똑같이 생김 -->
    <style>
        .date {
            width: 140px;
            height: 30px;
            font-size: 0.9em;
        }

        .btnsize {
            width: 100px;
            height: 30px;
            font-size: 0.8em;
            font-align: center;
            color: black;
        }

        .btnsize2 {
            width: 60px;
            height: 30px;
            font-size: 0.9em;
            color: black;
        }

        .ag-header-cell-label { /* 이것도 셀 정렬 기능인데 클래스를 부르지 않아서 안쓰는듯 */
            justify-content: center;
        }

        /*글자 밑에 있는거 중앙으로  */

        .ag-row .ag-cell {
            display: flex;
            justify-content: center !important; /* align horizontal */
            align-items: center !important;
        }

        .ag-theme-balham .ag-cell, .ag-icon .ag-icon-tree-closed::before {
            line-height: 15px !important;

        }

        .ag-group-contracted {
            height: 15px !important;

        }

        .ag-theme-balham .ag-icon-previous:before {
            content: "\f125" !important;
        }

        .ag-theme-balham .ag-icon-next:before {
            content: "\f11f" !important;
        }

        .ag-theme-balham .ag-icon-first:before {
            content: "\f115" !important;
        }

        .ag-theme-balham .ag-icon-last:before {
            content: "\f118" !important;
        }

    </style>
    <!-- css 선언 끝, script 선언 시작 -->
    <!-- doucument.ready로  DOM(Document Object Model) 객체가 생성되는 시점에 실행됨. function 안에 모든 것들이 실행됨
    이게 DOMCONTENSLOAD와 똑같다고 보면 됨. 물류 프로젝트에서는 그리드를 CONTENTSLOAD로 띄웠지만 회계는 DOCUMENT.READY방식으로 띄움, 둘이 똑같음-->
    <script>
        $(document).ready(function () {
            //버튼색 바꿔주는 이벤트
            $('input:button').hover(
                function () { // hover가 2개의 인자값이 있으면 첫번째 인자값은 마우스올렸을때 ,두번째는 땟을때 실행 - 마우스 올리면 노란색, 때면 무색
                    $(this).css("background-color", "yellow");
            },
                function () {
                    $(this).css("background-color", "");
            }
            );
            $("#search").click(searchSlip);         // (전표)검색
            $("#addSlip").click(addslipRow);            // 전표추가
            $("#deleteSlip").click(deleteSlip);      // 전표삭제 - 전표, 분개, 분개상세
            $("#addJournal").click(addJournalRow);      // 분개추가
            $("#deleteJournal").click(deleteJournal);   // 분개삭제, 화영이가 구현
            $("#showPDF").click(createPdf);             // pdf보기
            $("#saveSlip").click(saveSlip);              // 전표저장
            $("#confirm").click(confirmSlip);         // 결재 버튼
            $("#Accountbtn").click(searchAccount);   // 모달에서의 계정 검색 버튼
            $("#accountCode").keydown(function (key) { //모달창 안에서 계정과목 입력해서 찾아주는 메서드, 실행안됨 고쳐야됨, 누르는 순간 searchAccount 메서드 실행됨, 그 이후가 안되는듯
                if (key.code == 'Enter') {
                    searchAccount();
                }
            })
            $("#searchCodebtn").click(searchCode); // 모달에서의 부서 검색 버튼
            $("#searchCode").keydown(function (key) { //모달창 안에서 계정과목 입력해서 찾아주는 메서드, 실행안됨 고쳐야됨, 누르는 순간 searchAccount 메서드 실행됨, 그 이후가 안되는듯
                if (key.code == 'Enter') {
                    searchCode();
                }
            })
            $('.close').on('click', function(e){
                $("#accountGridModal").modal('hide');
                $("#customerCodeModalGrid").modal('hide');
                $("#codeModal").modal('hide');
            });
            /* DatePicker  */
            $('#from').val(today.substring(0, 8) + '01');//오늘날짜에서 맨뒤 두자리인 날짜는 01로 지정되도록 값을 세팅함, 초기값을 주는 형식, 날짜는 무조건 해당 달의 1일로 나타나게해둠
            $('#to').val(today.substring(0, 10));         // 오늘 날짜의 년-월-일, 마찬가지로 초기값을 주는거임

            <!-- 아래 모든 메서드들을 DOM 객체가 생성되는 시점에 실행함, 하나하나 다 볼것, 그리드도 여기서 만듬 -->
            createSlip();
            createJournal();
            createCodeGrid();
            showSlipGrid();                //시작하자마자 이번달 전표정보 보이게 해놓음 -> SlipController.findRangedSlipList 실행됨
            createAccountGrid();//계정 코드 조회 모달창 내부의 그리드 만드는 메서드임
            showAccount();
            createCustomerCodeGrid();
            createAccountDetailGrid()
            showAccountDetail('0101-0145') //처음 보이는 값이 당좌자산 첫번째껄로 보이게 해놓음, 두 사람에게 설명해줘야 야 함

            // DOM 로드될때 실행되는 순서 기록
            // createSlip 실행- createSlip 내부의 enableElement 실행 - createJournal 실행

        });
        window.addEventListener("keydown", (key) => {
            console.log(key);
            if (key.code == 'F2') {//keyCode 113번은 F2키를 뜻한다.
                addslipRow();
            } else if (key.code == 'F3') {//keyCode 114번은 F3키를 뜻한다.
                saveSlip();
            } else if (key.code == 'F4') {//keyCode 115번은 F4키를 뜻한다.
                confirmSlip();
            }
        })


        var NEW_SLIP_NO = "NEW"; // 전표 이름. 초기화 개념
        var NEW_JOURNAL_PREFIX = NEW_SLIP_NO + "JOURNAL"; // 분개 앞에 오는 이름
        var REQUIRE_ACCEPT_SLIP = "작성중";

        //그리드 선택자
        var slipGrid = "#slipGrid";
        var journalGrid = "#journalGrid";
        var accountGrid = "#accountGrid";
        var customerCodeModalGrid = "#customerCodeModalGrid";

        // 로그정보
        var deptCode = "${sessionScope.deptCode}";
        var accountPeriodNo = "${sessionScope.periodNo}";
        var empName = "${sessionScope.empName}";
        var empCode = "${sessionScope.empCode}";

        console.log(deptCode + "/" + accountPeriodNo + "/" + empName);

        //화폐 단위 원으로 설정 \100,000,000
        function currencyFormatter(params) {
            console.log("currencyFormatter(params) 실행");
            return '￦' + formatNumber(params.value);
        }

        function formatNumber(number) {
            console.log("formatNumber(number) 실행");
            // this puts commas into the number eg 1000 goes to 1,000,
            // i pulled this from stack overflow, i have no idea how it works
            return Math.floor(number)//floor함수는 항상 반올림한다는 뜻
                .toString()//글자로 바꾸고
                .replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,');//

            //Math.floor(Number(number).toLocaleString())
        }


        /* Event function 안에서 사용할 변수들 */
        var selectedSlipRow;
        var lastSelectedSlip;
        var lastSelectedJournal;
        var lastSelectedJournalDetail;
        var selectedJournalRow;
        var editRow;

        /* 날짜 */
        var date = new Date();
        var year = date.getFullYear().toString();
        //var month = (date.getMonth() + 1 > 9 ? date.getMonth() + 1 : '0' + (date.getMonth() + 1)).toString(); // getMonth()는 0~9까지
        var month = ("0" + (date.getMonth() + 1)).slice(-2);

        //var day = date.getDate() > 9 ? date.getDate() : '0' + date.getDate(); // getDate()는 1~31 까지
        var day = ("00" + date.getDate()).slice(-2)
        var today = year + "-" + month + "-" + day;


        // Map 내의 객체들 Disabled/Enabled
        function enableElement(obj) {

            console.log("enableElement(obj) 실행");
            console.log(obj);
            for (var key in obj)

                $(key).prop("disabled", !obj[key]);  //obj[key]부분은 true false밖에 올수없다.
        }


        // PDF로 보기
        function createPdf() {
            console.log("createPdf() 실행");
            window.open("${pageContext.request.contextPath}/base/report.html?method=FinancialPosition&slipNo=" + selectedSlipRow.slipNo);

        }


        // slipGrid
        var rowData;
        var gridOptions; //slipGrid 옵션
        var slipGrid;

        // slipGrid 생성
        // DOM 객체 생성되면 아래 createSlip 메서드 바로 실행됨, 콘솔창에 로그 기록됨
        // attribute sort 뜻이 뭐지? sort desc는 정렬을 의미하는 것으로 추측되지만 구글링해도 잘 모르겠음...
        // resizable 은 true가 default값, 열 너비 조정을 뜻함, 만약 false로 해놓으면 열 너비 수동으로 조정할 수 없음
        function createSlip() {
            console.log("createSlip() 실행");
            var columnDefs = [
                {headerName: "전표번호", field: "slipNo", sort: "desc", resizable: true, width: 100},
                {headerName: "기수", field: "accountPeriodNo", resizable: true, width: 70},
                {headerName: "부서코드", field: "deptCode", resizable: true, width: 80},
                {headerName: "부서", field: "deptName", resizable: true, hide: true},
                {headerName         : "구분",
                    field           : "slipType",
                    editable        : true,
                    cellEditor      : "agSelectCellEditor",
                    cellEditorParams: {values: ["결산", "대체"]},
                    width           : 70
                },
                {headerName: "적요", field: "expenseReport", editable: true, resizable: true},
                {headerName: "승인상태", field: "slipStatus", resizable: true, width: 100},
                {headerName: "상태", field: "status", resizable: true, hide: true},
                {headerName: "작성자코드", field: "reportingEmpCode", resizable: true, width: 100},
                {headerName: "작성자", field: "reportingEmpName", resizable: true, hide: true},
                {headerName: "작성일", field: "reportingDate", resizable: true, width: 100},
                {headerName: "직급", field: "positionCode", resizable: true, hide: true}
            ];

            gridOptions = {
                columnDefs                   : columnDefs,
                rowSelection                 : 'single', //row는 하나만 선택 가능
                defaultColDef                : {editable: false}, // 정의하지 않은 컬럼은 자동으로 설정
                pagination                   : true, // 페이저
                paginationPageSize           : 10, // 페이저에 보여줄 row의 수
                stopEditingWhenGridLosesFocus: true, // 그리드가 포커스를 잃으면 편집 중지
                onGridReady                  : function (event) {// onload 이벤트와 유사 ready 이후 필요한 이벤트 삽입한다.
                    event.api.sizeColumnsToFit(); // 그리드의 사이즈를 자동으로정리 (처음 틀었을때 양쪽 폭맞춰주는거같음)
                },
                onGridSizeChanged            : function (event) { // 그리드의 사이즈가 변하면 자동으로 컬럼의 사이즈 정리  (화면 비율바꿧을때 양쪽폭 맞춰줌)
                    event.api.sizeColumnsToFit();
                },
                onRowClicked                 : function (event) {
                    console.log("sliprow선택");
                    selectedSlipRow = event.data;
                    console.log(selectedSlipRow);
                    showJournalGrid(event.data["slipNo"]); //셀 클릭하는 순간 선택한 셀의 데이터가 콘솔에 출력됨, 그리고 showJournalGrid 메서드가 실행됨


                    if (selectedSlipRow.slipStatus != '승인완료') { // 선택한 로우의 slipStatus의 값이 승인완료가 아니라면 아래 4항목 true로, 값이 승인완료라면 아래 4항목 false로 바꿈
                        enableElement({
                            "#deleteSlip"   : true,  //전표삭제버튼
                            "#addJournal"   : true,  //분개추가버튼
                            "#deleteJournal": true,  //분개삭제버튼
                            "#confirm"      : true   //결재신청버튼
                        });
                    } else {
                        enableElement({
                            "#deleteSlip"   : false,
                            "#addJournal"   : false,
                            "#deleteJournal": false,
                            "#confirm"      : false
                        })
                    }
                    ;
                },
            };
            slipGrid = document.querySelector('#slipGrid');  //Body에 선언해놓은 Grid Id값을 쿼리셀렉터로 가져와서 slipGrid 변수 세팅하고 newagGrid.Grid(slipGrid, gridOptions)로 그리드에 데이터를 집어넣음
            new agGrid.Grid(slipGrid, gridOptions);          //그리드 자체는 이미 dom객체가 생성될 때 만들어져 있는 상태였음, 값만 넣은 것
            enableElement({
                "#addSlip"      : true,
                "#deleteSlip"   : false,
                "#addJournal"   : false,
                "#deleteJournal": false,
                "#showPDF"      : false,//수정
            });


           // gridOptions.api.setRowData([]);  // 왜 빈값으로 할당하지 ?(dong)
        }


        // 전표 추가 버튼 이벤트
        function addslipRow() {
            console.log("addslipRow() 실행");
            console.log(accountPeriodNo);
            $.ajax({
                type    : "GET",
                url     : "${pageContext.request.contextPath}/posting/accountingsettlementstatus",
                data    : {
                    "accountPeriodNo": accountPeriodNo,
                    "callResult"     : "SEARCH"			/////// 회계결산현황 조회(SEARCH) 및 호출
                },
                dataType: "json",
                success : function (jsonObj) {
                    console.log("jsonObj",jsonObj);
                    console.log(accountPeriodNo);
                    addslipShow();
                    //console.log(jsonObj.accountingSettlementStatus); jsonObj에 이런 데이터 없음, 쓸모없는 코드

                }
            });
        }

        // 전표 빈 양식
        function addslipShow() {
            console.log("addslipShow() 실행");
            comfirm = false; //comfirm --> 확인창 안뜨게
            rowData = [];
            slipObj = {
                "slipNo"          : NEW_SLIP_NO,
                "accountPeriodNo" : accountPeriodNo,
                "slipType"        : "결산",	// sliptye의 결산 삭제시 위의 event.data['slipType'] 동작
                "slipStatus"      : REQUIRE_ACCEPT_SLIP,
                "deptCode"        : deptCode,
                "reportingEmpCode": empCode,
                "reportingEmpName": empName,
                "reportingDate"   : today,
            };

            enableElement({"#addSlip": false});  // 버튼 비활성화 - 전표추가버튼 비활성화


            var newObject = $.extend(true, {}, slipObj); //slipObj에 값이 전부 입력되면 newObject에 담긴다
            rowData.push(newObject); //rowData 집어넣는다
            gridOptions.api.applyTransaction({add: rowData});  // 행데이터를 업데이트, add/remove에 대한 목록이 있는 트랜잭션 객체를 전달

        }


        // 전표 삭제 이벤트
        function deleteSlip() {
            console.log("deleteSlip() 실행");
            console.log("selectedSlipRow.slipNo :" + selectedSlipRow.slipNo);

            //var selectedRows = gridOptions.api.getSelectedRows(); //내가 선택한 값을 selectRows에 담는다 (수정)
            if (selectedSlipRow['slipStatus'] == "승인요청" || selectedSlipRow['slipStatus'] == "승인완료") {
                alert("전표 작성중이 아닙니다.\n현재상태 : " + selectedSlipRow['slipStatus']);
            } else {

                if (confirmDelete()) {
                    $.ajax({
                        type: "GET",
                        url : "${pageContext.request.contextPath}/posting/slipremoval",
                        data: {
                            "slipNo": selectedSlipRow.slipNo
                        },

                        success: function () {
                            console.log("data 전달 성공")
                            var isNewSlip = (selectedSlipRow.slipNo == NEW_SLIP_NO); // 삭제한다음에 전표추가가 안되서 수정함 (dong)
                            enableElement({
                                "#addSlip"      : true,
                                "#deleteSlip"   : false,
                                "#addJournal"   : false,
                                "#deleteJournal": false,
                                "#createPdf"    : false,
                            });

                            gridOptions.api.applyTransaction({remove: [selectedSlipRow]});  //선택된 전표 삭제 (choi)

                        }
                    });
                }
                enableElement({
                    "#addSlip"      : true,
                    "#deleteSlip"   : false,
                    "#addJournal"   : false,
                    "#deleteJournal": false,
                    "#createPdf"    : false,
                });
                gridOptions.api.applyTransaction({remove: [selectedSlipRow]});
            }

        }

        function confirmDelete()//삭제 메세지
        {
            msg = "삭제하시겠습니까?";
            if (confirm(msg) != 0) {
                return true;
            } else {
                return false;
            }
        }

        // 분개삭제 (수정함)
        function deleteJournal() {

            if (selectedJournalRow == null || selectedSlipRow.slipNo == NEW_SLIP_NO) {
                if (selectedJournalRow == null) {
                    alert("삭제할 분개를 선택해주세요.");
                    console.log("selectedJournalRow", selectedJournalRow);
                } else {
                    alert("NEW 차변,대변은 삭제할 수 없습니다");
                }

            } else {
                $.ajax({
                    type   : "GET",
                    url    : "${pageContext.request.contextPath}/posting/journalremoval",
                    data   : {
                        "journalNo": selectedJournalRow["journalNo"]
                    },
                    success: function () {
                        console.log("deleteJournal성공");

                        enableElement({
                            "#addSlip"      : true,
                            "#deleteSlip"   : true,
                            "#addJournal"   : true,
                            "#deleteJournal": true,
                            "#createPdf"    : false,
                        });
                        //selectedRows.forEach(function (selectedRow, index) { //forEach 배열의 반복문
                        gridOptions2.api.applyTransaction({remove: [selectedJournalRow]}); // db에 저장된 분개 삭제  (choi)
                        //});
                    }
                });
                //showJournalGrid(selectedSlipRow.slipNo);  // 호출안해도 될것같은데ㅔ; ? (dong)
            }
        }

        // journalslip
        var rowData2;
        var gridOptions2 //jouranlGrid 옵션
        var journalGrid;
        var selectedJournalRow;
        var detailGridApi;

        //Journal 생성
        //먼저 gridOptions 칼럼에 들어갈 값과 함수들 선언. 결국 그리드에 값 넣고 띄우려면 aggrid.grid(grid 태그 id값, gridOptions) 를 실행하면 된다.
        function createJournal() {
            console.log("createJournal() 실행");
            rowData2 = [];
            gridOptions2 = {
                columnDefs                   : [
                    {
                        headerName  : "분개번호", field: "journalNo",
                        cellRenderer: 'agGroupCellRenderer',  // Style & Drop Down  //cellRenderer 는 사용자에게 확장 및 축소 시능을 제공하는 attribute다, 키는 agGroupCellrenderer이며, 사용했을 시 많은 속성을 사용할 수 있다.
                        sort        : "asc", resizable: true, onCellDoubleClicked: cellDouble  //이건 onCellDoubleClick을 했을 시 cellDouble 메서드를 실행시킨다는 거임, 앞에 적혀있는건 메서드실행하는거 아님 둘이 다름. 명심!!
                    },
                    {
                        headerName      : "구분", field: "balanceDivision", editable: true,
                        cellEditor      : "agSelectCellEditor",
                        cellEditorParams: {values: ["차변", "대변"]}
                    },
                    {
                        headerName: "계정코드", field: "accountCode"
                        , editable: true
                    },
                    {
                        headerName   : "계정과목", field: "accountName",

                        onCellClicked: function open() {  //계정과목 더블클릭시 모달창 띄우고 searchAccount 메서드 실행. 모달창 검색창에 계정과목 한글로 검색하면 관련된 계정과목이 오른쪽 그리드에 출력되도록 쿼리문 짜져있음
                            $("#accountGridModal").modal('show');
                            searchAccount();
                        }
                    },
                    {
                        headerName    : "차변", field: "leftDebtorPrice",
                        editable      : params => {
                            if (params.data.balanceDivision === '대변') return false  //구분 컬럼에 있는 대변or차변에 따라 서로 다르면 수정을 못하도록 false값 줬음, 차변구분이 차변일때 수정가능, 대변구분이 대변일때 수정가능하도록 만들어둠
                            else return true
                        },
                        valueFormatter: currencyFormatter		// 통화 값에 대한 로캘별 서식 지정 및 파싱을 제공, 함수로 설정해둠, 금액 입력시 '￦'가 나타나게 한다. 검색하면 함수있음
                    },
                    {
                        headerName    : "대변", field: "rightCreditsPrice",
                        editable      : params => {
                            if (params.data.balanceDivision === '차변') return false
                            else return true
                        },
                        valueFormatter: currencyFormatter
                    },
                    //수정중
                    {
                        headerName   : "거래처", field: "customerName",
                        onCellClicked: function open() {        //거래처 셀 클릭하면 거래서코드모달그리드 창이 열리면서 동시에 searchCustomerCodeList()메서드를 실행한다.
                            $("#customerCodeModalGrid").modal('show');
                            searchCustomerCodeList();
                        }

                    },
                    //{headerName: "거래처", field: "customerName", hide: true}, -- 필요없는 코드, 중복임
                    {headerName: "상태", field: "status"}
                ],
                masterDetail                 : true,  //masterDetail 이 표시된 그리드는 최상위 그리드를 나타냅니다. 행이 확장되면 관련된 세부정보가 포함된 다른 그리드가 표시됨, 그런건 상세그리드라고 함.
                                                      //masterDetail을 표시해두면 detailCellRendererParams에서 상세 그리드를 나타낼 수 있다.
                enableCellChangeFlash        : true,  //true일때 변경사항이 감지되면 셀이 깜빡이도록 허용한다. -- 보면 거래처나 차변, 대변값이 들어갈때마다 초록색으로 살짝 깜빡인다.
                detailCellRendererParams     : {      //하위 그리드에서 가지고 있는 옵션, 이건 모달창에 뜨는 그리드랑 약간 다르다.
                    detailGridOptions: {              //하위 그리드
                        rowSelection          : 'single',
                        enableRangeSelection  : true,		// 끌어서 선택옵션
                        pagination            : true,
                        paginationAutoPageSize: true, //지정된 사이즈내에서 최대한 많은 행을 표시
                        columnDefs            : [
                            {headerName: "분개번호", field: "journalNo", hide: true},
                            {headerName: "계정 설정 속성", field: "accountControlType", width: 150, sortable: true},
                            {headerName: "분개 상세 번호", field: "journalDetailNo", width: 150, sortable: true},
                            {headerName: "-", field: "status", width: 100, hide: true},
                            {headerName: "-", field: "journalDescriptionCode", width: 100, hide: true},
                            {headerName: "분개 상세 항목", field: "accountControlName", width: 150,},
                            {
                                headerName  : "분개 상세 내용",
                                field       : "journalDescription",
                                width       : 250,
                                cellRenderer: cellRenderer //????????????????
                            },
                        ],
                        defaultColDef         : {
                            sortable: true,
                            flex    : 1,			//  flex로 열 크기를 조정하면 해당 열에 대해 flex가 자동으로 비활성화
                        },
                        getRowNodeId          : function (data) {
                            console.log("getRowNOdeId 실행");
                            // use 'account' as the row ID
                            console.log("getRowNodeId: " + data.journalDetailNo);
                            return data.journalDetailNo;
                        },
                        onRowClicked          : function (event) {
                            console.log("onRowClicked 실행");
                            selectedJournalDetail = event.data;
                            selectedJournalRow = event.data;
                            console.log(selectedJournalDetail);
                            console.log("하위그리드의 selectedJournalDetail값 : " + selectedJournalDetail);
                            console.log("하위그리드의 selectedJournalRow값 :" + selectedJournalRow);

                        },
                        onCellDoubleClicked   : function (event) { //작동안됨, 하위 그리드 두번 누를 시 뭔가가 실행되야되는데 안됨. 알아보자
                            console.log("onCellDoubleClicked 실행");
                            var journalNo = event.data["journalNo"];
                            console.log("journalNo : "+journalNo);
                            detailGridApi = gridOptions2.api.getDetailGridInfo('detail_' + journalNo); //주어진 값에 detail접두사를 붙여 상세 그리드의 ID를 생성한다.
                            console.log("detailGridApi : "+detailGridApi);
                            console.log(detailGridApi);

                            if (event.data["accountControlType"] == "SEARCH") {  //계정설정속성이 search라면 codeModal 띄우고 값 넣기
                                $("#codeModal").modal('show');
                                detailGridApi.api.applyTransaction([selectedJournalDetail["journalDescription"] = searchCode()]);

                                return;
                            } else if (event.data["accountControlType"] == "SELECT") {
                                // var detailGrid=gridOptions.api.getDetailGridInfo('detail_'+event.data.journalDetailNo);
                                detailGridApi.api.applyTransaction([selectedJournalDetail["journalDescription"] = selectBank()]);

                                return;
                            } else if (event.data["accountControlType"] == "TEXT") {
                                var str = prompt('상세내용을 입력해주세요', '');
                                console.log('detail_' + event.data.journalDetailNo);
                                //var detailGrid=gridOptions2.api.getDetailGridInfo('detail_'+event.data.journalDetailNo);
                                detailGridApi.api.applyTransaction([selectedJournalDetail["journalDescription"] = str]);
                                saveJournalDetailRow();

                                return;
                            } else {
                                //var detailGrid=gridOptions2.api.getDetailGridInfo('detail_'+event.data.journalDetailNo);
                                detailGridApi.api.applyTransaction([selectedJournalDetail["journalDescription"] = selectCal()]);

                                return;
                            }

                        }
                    },

                    getDetailRowData: function (params) {
                        console.log("getDetailRowData 실행");
                        console.log(params.data.journalDetailList);
                        params.successCallback(params.data.journalDetailList); // detail table 에 값 할당
                    },
                    template        : function (params) {
                        return (
                            '<div style="height: 100%; background-color: #EDF6FF; padding: 20px; box-sizing: border-box;">' +
                            '  <div style="height: 10%; padding: 2px; font-weight: bold;">분개상세</div>' +
                            '  <div ref="eDetailGrid" style="height: 90%;"></div>' +
                            '</div>'
                        );
                    },
                },
                getRowNodeId                 : function (data) {
                    console.log("getRowNodeId 실행");
                    // use 'account' as the row ID
                    console.log("getRowNodeId: " + data.journalNo);
                    return data.journalNo;
                },
                enterMovesDownAfterEdit      : true,
                rowSelection                 : 'single',
                stopEditingWhenGridLosesFocus: true,
                onGridReady                  : function (event) {
                    event.api.sizeColumnsToFit();
                },
                onGridSizeChanged            : function (event) { // 그리드의 사이즈가 변하면 자동으로 컬럼의 사이즈 정리
                    event.api.sizeColumnsToFit();
                },

                onCellEditingStopped: function (event) {
                    //gridOptions2.api.tabToNextCell();

                    console.log("onCellEditingStopped 실행");
                    console.log(event);

                    if (event.colDef.field == 'leftDebtorPrice' || event.colDef.field == 'rightCreditsPrice') {
                        computeJournalTotal();  // 바뀐행이 이 차변,대변이면 실행하도록 수정(dong)

                    }
                    ;
                    if (event.colDef.field == 'accountCode') {// 항상 실행되던거 accouncode 수정될때만 실행되도록 수정(dong)
                        $.ajax({
                            type    : "GET",
                            url     : "${pageContext.request.contextPath}/operate/accountcontrollist",
                            data    : {
                                accountCode: event.data["accountCode"] // 계정코드
                            },
                            dataType: "json",
                            async   : false,
                            success : function (jsonObj) {
                                console.log(selectedJournalRow['journalDetailList']);
                                console.log("바꾼 데이터",jsonObj);
                                console.log(JSON.stringify(jsonObj));
                                //jsonObj에는 account_control_code , account_control_name , account_control_type , account_control_description 만 가지고옴
                                jsonObj.forEach(function (element, index) { //accountControl은 map의 key 이름, accountControlList가 들어있음
                                    element['journalNo'] = selectedJournalRow['journalNo'];  // accountControlList에는 journalNo가 없어서 셋팅 후 아래 그리드옵션에 할당
                                })
                                gridOptions2.api.applyTransaction(selectedJournalRow['journalDetailList'] = jsonObj);
                                console.log(selectedJournalRow['journalDetailList']);
                            }
                        });
                        Price(event);

                    }
                    ;


                },
                onCellValueChanged  : function (event) {  // onCellEditingStopped에 있으면 금액수정할때도 계속 실행되서 수정함(dong)
                    selectedJournalRow = event.data;
                    if (event.colDef.field == 'accountCode') {
                        getAccountName(event.data['accountCode']);
                    }
                },
                onRowClicked        : function (event) {
                    console.log("onRowClicked 실행");
                    selectedJournalRow = event.data;
                    console.log(selectedJournalRow);
                }
            };
            journalGrid = document.querySelector('#journalGrid');
            new agGrid.Grid(journalGrid, gridOptions2);
        }

        function cellDouble(event) {  //분개번호 칼럼을 더블클릭시 실행되는 메서드
            console.log("cellDouble(event) 실행");
            console.log(selectedSlipRow["slipNo"]);
            console.log(NEW_SLIP_NO);
            console.log(selectedJournalRow); // 셀 한번 클릭하는 순간 위애서 eventdata로 여기에 값을 넣어버림, 그래서 더블클릭하면 무조건 이 값이 들어있을 수 밖에 없게 해놈
            if (selectedSlipRow["slipNo"] !== NEW_SLIP_NO) {  //두개는 항상 다르게 되어있는데 굳이 조건식을 건 이유는?
                //분개상세 보기
                $.ajax({
                    type: "GET",
                    // JournalDetailDAO- ArrayList<JournalDetailBean> selectJournalDetailList(String journalNo)- return journalDetailBeans
                    url     : "${pageContext.request.contextPath}/posting/journaldetaillist",   //요기로 이동, journalNo를 파라미터로 보냄
                    data    : {
                        "journalNo": selectedJournalRow["journalNo"] //선택한 분개번호 no를 파라매터로 넘김
                    },
                    dataType: "json",
                    success : function (jsonObj) {
                        console.log(JSON.stringify(jsonObj)); //데이터 잘 들고오는지 확인
                        detailGridApi.api.setRowData(jsonObj); //가져온 데이터를 gridOption4의 칼럼명에 맞게 하나하나 세팅해주기
                    }
                });
            }
        }

        // 차변 대변 입력
        // var errBoolean = false;
        var lastIndex;
        var lastRow;

        function Price(event) {
            console.log("price(event) 실행");
            lastIndex = gridOptions2.api.getFirstDisplayedRow();  //0
            lastRow = gridOptions2.api.getRowNode(lastIndex);  // undifine  (dong)
            console.log("lastIndex",lastIndex);
            console.log("lastRow",lastRow)


            var sum = 0;
            if (event.data['journalNo'] != "Total") {
                if (event.data['balanceDivision'] == "차변") {
                    var price = prompt("차변의 금액을 입력해주세요", "");
                    price = price == null ? 0 : price;
                    if (!isNaN(price)) {
                        gridOptions2.api.applyTransaction([event.data['rightCreditsPrice'] = 0]);
                        gridOptions2.api.applyTransaction([event.data['leftDebtorPrice'] = price]);

                        computeJournalTotal();
                    } else {
                        alert("숫자만 입력해주세요");
                    }

                }
                if (event.data['balanceDivision'] == "대변") {
                    var price = prompt("대변의 금액을 입력해주세요", "");
                    price = price == null ? 0 : price;
                    if (!isNaN(price)) {
                        gridOptions2.api.applyTransaction([event.data['leftDebtorPrice'] = 0]);
                        gridOptions2.api.applyTransaction([event.data['rightCreditsPrice'] = price]);

                        computeJournalTotal();
                    } else {
                        alert("숫자만 입력해주세요");
                    }
                }
            }
            var totalIndex = (gridOptions2.api.getDisplayedRowCount()) - 1;
            var totalRow = gridOptions2.api.getDisplayedRowAtIndex(totalIndex); // lastRow.data 이게 먹통이라 소스 수정(dong)

            if (totalRow.data['leftDebtorPrice'] != 0 && totalRow.data['rightCreditsPrice'] != 0) {
                if (totalRow.data['leftDebtorPrice'] != totalRow.data['rightCreditsPrice']) {
                    alert("차변과 대변이 일치하지 않으면 승인이 거부될 수 있습니다.");

                }
            }
        }


        function saveSlip(confirm) {//전표저장, 현재는 잘 안돌아감
            console.log("confirm",confirm);//내가 누른 이벤트의 정보들
            var JournalTotalObj = [];
            var slipStatus = confirm == "승인요청" ? confirm : null //기본은 null이고 confirm할때만 "승인요청"으로 바뀐다
            console.log("slipStatus",slipStatus);//null값 나옴
            if (selectedSlipRow['slipStatus'] == "승인요청" || selectedSlipRow['slipStatus'] == "승인완료") {
                alert("전표 작성중이 아닙니다.\n현재상태 : " + selectedSlipRow['slipStatus']);  //먼저 한번 걸러줌
            } else {
                console.log("저장 시작")
                gridOptions2.api.forEachNode(function (node, index) {//gridOptions2의 값을 하나하나 JournalTotalObj에 담음

                    if (node.data.journalNo != "Total") {
                        JournalTotalObj.push(node.data); //분개노드 마지막 total 빼고 JournalTotalObj에 담음
                        console.log(" JournalTotalObj.push(node.data) :" + JSON.stringify(node.data));
                        console.log(" JournalTotalObj.push(node.data2) :" + JSON.stringify(JournalTotalObj));
                    }
                });
                debugger
                console.log("Ajax 통신 시작")
                console.log(selectedSlipRow['slipNo']);
                console.log(NEW_SLIP_NO);
                if (selectedSlipRow['slipNo'] == NEW_SLIP_NO) { //선택된 로우가 new면
                    console.log("NEW 전표입력")
                    $.ajax({
                        type    : "POST",
                        url     : "${pageContext.request.contextPath}/posting/registerslip",
                        data    : {
                            "slipObj"   : JSON.stringify(selectedSlipRow),
                            "journalObj": JSON.stringify(JournalTotalObj),
                            "slipStatus": slipStatus
                        },
                        async   : false,		// 동기식   // 비동기식으로할경우 아래 showslipgrid에서 값을 못불러올수있다.
                        dataType: "json",
                        complete : function () { //return 값이 필요 없음(choi)success 왜안됨?
                            console.log("새 전표 저장 완료")
                            enableElement({"#addSlip": true});
                            location.reload();
                        }
                    });
                } else if (selectedSlipRow['slipNo'] != NEW_SLIP_NO) { //기존 저장 후 수정 및 반려 후 저장
                    console.log("기존 전표입력")
                    var JournalTotalObj2 = [];
                    gridOptions2.api.forEachNode(function (node, index) {
                        gridOptions2.api.applyTransaction([node.data["status"] = "update"]);
                        JournalTotalObj2.push(node.data);
                        console.log("slipStatus:" + slipStatus);
                        console.log(" JournalTotalObj.push(node.data)!!!! :" + JSON.stringify(JournalTotalObj));
                    });
                    //  saveJournal(selectedSlipRow["slipNo"], JournalTotalObj2); 삭제(dong)
                    $.ajax({
                        type    : "POST",
                        url     : "${pageContext.request.contextPath}/posting/slipmodification",
                        data    : {
                            "slipObj"   : JSON.stringify(selectedSlipRow),
                            "journalObj": JSON.stringify(JournalTotalObj),
                            "slipStatus": slipStatus
                        },
                        async   : false,
                        dataType: "json",
                        success : function (jsonObj) {
                            enableElement({"#addSlip": true});
                            console.log("slipNo:" + jsonObj.slipNo);

                        }
                    });
                }

                if (confirm == "승인요청") alert("결제 신청이 완료되었습니다.");
                else alert("저장 되었습니다.");
                showSlipGrid();
                showJournalGrid(selectedSlipRow.slipNo);
            }
            console.log("Ajax 통신 끝")
        }

        function confirmSlip() {
            console.log("comfirmSlip() 실행");
            var result = true;
            var compare = compareDebtorCredits();  // for문 안에서 계속 실행되서 밖으로 꺼냄, 한번만 실행되도됨(dong)
            var approvalStatus = compare.isEqualSum; //isEqualSum=true
            gridOptions2.api.forEachNode(function (rowNode, index) { //forEachNode=forEach
                if (rowNode.data["journalNo"] != "Total") { //토탈이 아니면 == 차변과 대변이면
                    if (rowNode.data["balanceDivision"] == null) {
                        alert("구분(분개필수 항목)을 확인해주세요");
                        result = false;
                        return;
                    }
                    if (rowNode.data["accountCode"] == null) {
                        alert("계정코드(분개필수 항목)을 확인해주세요");
                        result = false;
                        return;
                    }
                    if (rowNode.data["accountName"] == null) {
                        alert("계정과목(분개필수 항목)을 확인해주세요");
                        result = false;
                        return;
                    }
                    if (!approvalStatus) {    //대변의 합과 차변의 합이 같지 않으면
                        alert("전표의 차변/대변 총계가 일치하지않습니다.\n 차변/대변 총계를 확인해주세요.");
                        result = false;
                        return;
                    }
                }
            });


            if (selectedSlipRow['slipStatus'] == "승인요청" || selectedSlipRow['slipStatus'] == "승인완료") {
                alert("전표 작성중이 아닙니다.\n현재상태 : " + selectedSlipRow['slipStatus']);
            } else if (result) {
                saveSlip("승인요청");
            }

        }

        function compareDebtorCredits() { // 대변차변 합계 일치 여부 확인
            console.log("compareDebotrCredits() 실행");
            var isEqualSum;
            var debtorPriceSum = 0;
            var creditsPriceSum = 0;

            gridOptions2.api.forEachNode(function (node) {
                debtorPriceSum += parseInt(node.data.leftDebtorPrice);
                creditsPriceSum += parseInt(node.data.rightCreditsPrice);
            });
            var result = {isEqualSum: debtorPriceSum == creditsPriceSum};

            return result;
        }


        //분개 추가
        function addJournalRow() {
            console.log("addJournalRow 실행");

            if (selectedSlipRow["expenseReport"] == "") {
                alert("적요란을 기입하셔야 합니다.");
                return;
            }
            var journal = gridOptions2.api.getDisplayedRowCount() == 0 ? 1 : gridOptions2.api.getDisplayedRowCount();// 현재 보여지는 로우의 수를 반환
            var journalObj = {
                "journalNo"        : NEW_JOURNAL_PREFIX + journal, //이부분이 분개번호
                "leftDebtorPrice"  : 0,  //차변 금액
                "rightCreditsPrice": 0,  //대변 금액
                "status"           : "insert"
            };
            var newObject2 = $.extend(true, {}, journalObj);
            gridOptions2.api.applyTransaction({add: [newObject2]});

            enableElement({
                "#addSlip"      : false,
                "#deleteSlip"   : true,
                "#addJournal"   : true,
                "#deleteJournal": true,
                "#createPdf"    : true,

            });
        }


        //찾기
        function searchSlip() {
            console.log("searchSlip() 실행");
            enableElement({
                "#addSlip"      : true,
                "#deleteSlip"   : false, //비활성화
                "#addJournal"   : false,
                "#deleteJournal": false,
                "#showPDF"      : true,
            });
            showSlipGrid();
            console.log("pdf abled");
        }

        //전표 보기
        //날짜값(from, to)와 slipStatus에 value값을 파라매터로 보낸다
        function showSlipGrid() {   // 먼저 날짜 데이트를 받고 / 전표추가시 오늘날짜를 actual argument로 넘긴다.
            console.log($("#selTag").val());
            $.ajax({
                url     : "${pageContext.request.contextPath}/posting/rangedsliplist",
                data    : {
                    "fromDate"  : $("#from").val(),
                    "toDate"    : $("#to").val(),
                    "slipStatus": $("#selTag").val()
                },
                dataType: "json",
                success : function (jsonObj) {

                    gridOptions.api.setRowData(jsonObj);
                    gridOptions2.api.setRowData([]);

                },
                async   : false //비동기방식설정 - 순서대로 처리
            });
            /*                         return isSuccess; */
        }

        // 분개 보기
        function showJournalGrid(slipNo) { //slip rowid 선택한 전표행이다
                                            //여기 로직 너무 수상함, rodata2가 콘솔에 찍으면 초기화 안된 상태임, debugger모드를 통해 콘솔로 찍어보면 제대로나옴, 왜지? ajax통신을 비동기식으로 한 이유는? 왜?
            // show loading message
            console.log("showJournalGrid(" + slipNo + ") 실행");

            rowData2 = [];

            console.log("저기",rowData2);
            var journalObj = {
                "journalNo"        : "Total", //이부분이 분개번호
                "leftDebtorPrice"  : 0,  //차변 금액
                "rightCreditsPrice": 0,  //대변 금액
                "status"           : ""
            };
            var totalObject = $.extend(true, {}, journalObj);//데이터를 합치는 것, 원래 배열의 값을 유지하기 위해 true 인자를 넣는다.?????

            console.log("요기", rowData2);
            console.log("여기",totalObject);
            rowData2.push(totalObject);
            console.log(rowData2);


            if (selectedSlipRow["slipNo"] !== NEW_SLIP_NO) {//내가 선택한 로우의 전표번호가 NEW가 아니면 실행
                console.log("김승현")
                $.ajax({
                    type    : "GET",
                    async   : false,
                    url     : "${pageContext.request.contextPath}/posting/singlejournallist",
                    data    : {
                        "slipNo": slipNo
                    },
                    dataType: "json",
                    success : function (jsonObj) {//선택한 전표에 등록된 분개정보값 다 가져와서 rowData2에 푸쉬함

/*debugger*/
                        console.log("@@@@@@@@@@@@jsobObj : " + JSON.stringify(jsonObj));
                        jsonObj.forEach(function (element) {
                                console.log("바보",element)
                                rowData2.push(element);
                            }

                        );
                        console.log("rowData2",rowData2)


                        jsonObj.forEach(function (element, index) {//element의 journalDetailList bean을 콘솔창에 반복출력해봄, 어디쓰는진 아직 모르겠음


                            $.ajax({
                                type    : "GET",
                                async   : false,
                                url     : "${pageContext.request.contextPath}/posting/journaldetaillist",
                                data    : {
                                    "journalNo": element["journalNo"] //rowid 분개번호임
                                },
                                dataType: "json",
                                success : function (jsonObj) {
                                    element.journalDetailList = jsonObj;
                                }
                            });
                            console.log("element",element.journalDetailList);
                        });

                    }
                });
            } else {//내가 선택한 로우의 전표번호가 NEW 일때 실행
                console.log("NEW전표번호 생성")
                var journalObj = { //분개1 생성
                    "journalNo"        : NEW_JOURNAL_PREFIX + 1, //이부분이 분개번호 NEW_JOURNAL_PREFIX = NEW_SLIP_NO + "JOURNAL"
                    "balanceDivision"  : "차변",
                    "leftDebtorPrice"  : 0,  //차변 금액
                    "rightCreditsPrice": 0,  //대변 금액
                    "status"           : "insert"
                };
                var journalObj1 = { //분개 2 생성
                    "journalNo"        : NEW_JOURNAL_PREFIX + 2, //이부분이 분개번호
                    "balanceDivision"  : "대변",
                    "leftDebtorPrice"  : 0,  //차변 금액
                    "rightCreditsPrice": 0,  //대변 금액
                    "status"           : "insert"
                };
                var newJournal1 = $.extend(true, {}, journalObj);  // 굳이 이렇게 변수에 담은다음에 배열에 넣을필요있나 ?바로넣지..? 수정하쟈(dong)
                var newJournal2 = $.extend(true, {}, journalObj1);
                rowData2.push(newJournal1);
                rowData2.push(newJournal2);
            }



            gridOptions2.api.setRowData(rowData2);//rowData2를 gridOptions2에 세팅, 그다음 computeJournalTotal메서드 실행
            computeJournalTotal();
        }

        <!-- 분개모달창시작 -->
        var accountGrid;
        var gridOptionsAccount;

        function createAccountGrid() { //계정 코드 조회 모달창 내부의 그리드 만드는 메서드임
            rowData = [];
            var columnDefs1 = [
                {
                    headerName: "계정과목 코드", field: "accountInnerCode", sort: "asc", width: 120, resizable: true,
                    cellClass : "grid-cell-centered"
                },//셀의 내용을 중심에 맞춤
                {headerName: "계정과목", field: "accountName", resizable: true, cellClass: "grid-cell-centered"},
            ];
            gridOptionsAccount = {
                columnDefs       : columnDefs1,
                rowSelection     : 'single', //row는 하나만 선택 가능
                defaultColDef    : {editable: false}, // 정의하지 않은 컬럼은 자동으로 설정 //수정할 수 없도록 해둔거임
                onGridReady      : function (event) {// onload 이벤트와 유사 ready 이후 필요한 이벤트 삽입한다.
                    event.api.sizeColumnsToFit();
                },
                onGridSizeChanged: function (event) { // 그리드의 사이즈가 변하면 자동으로 컬럼의 사이즈 정리
                    event.api.sizeColumnsToFit();
                },
                onRowClicked     : function (event) {//로우 누르는 순간 showAccountDetail 메서드에 매개변수 전달해서 실행
                    console.log("Row선택");
                    console.log(event.data);
                    selectedRow = event.data;
                    showAccountDetail(selectedRow["accountInnerCode"]);//계정과목 번호 ex)0218-0230값 전달
                }
            }

            accountGrid = document.querySelector('#accountGrid');
            new agGrid.Grid(accountGrid, gridOptionsAccount);
        }

        function showAccount() { //부모코드 조회함
            $.ajax({
                type    : "GET",
                url     : "${pageContext.request.contextPath}/operate/parentaccountlist",
                data    : {},
                dataType: "json",
                success : function (jsonObj) {
                    gridOptionsAccount.api.setRowData(jsonObj); //gridOptionsAccount에 값 붙임
                }
            });
        }

        <!-- 분개상세모달창시작 --> <!-- 분개상세모달 아님, 계정코드 조회 시 나오는 오른쪽 그리드 -->

        var gridOpionsAccountDetail




        function createAccountDetailGrid() {
            console.log("createAccountDetailGrid() 실행");
            rowData = [];
            var columnDefs = [
                {headerName: "계정과목 코드", field: "accountInnerCode", width: 120, sortable: true, resizable: true,},
                {headerName: "계정과목", field: "accountName", sortable: true, resizable: true,},
            ];

            gridOpionsAccountDetail = {
                columnDefs   : columnDefs,
                rowSelection : 'single', //row는 하나만 선택 가능
                defaultColDef: {editable: false}, // 정의하지 않은 컬럼은 자동으로 설정
                /*                             pagination: true, // 페이저
                                            paginationPageSize: 15, // 페이저에 보여줄 row의 수 */
                onGridReady        : function (event) {// onload 이벤트와 유사 ready 이후 필요한 이벤트 삽입한다.
                    event.api.sizeColumnsToFit();
                },
                onGridSizeChanged  : function (event) { // 그리드의 사이즈가 변하면 자동으로 컬럼의 사이즈 정리
                    event.api.sizeColumnsToFit();
                },

                onCellDoubleClicked: function (event) {//오른쪽 그리드 로우 더블클릭 시 모달창 사라지고 분개 그리드의 값을 클릭했던 로우 값으로 바꾼다.
                    $("#accountGridModal").modal('hide');
                    gridOptions2.api.applyTransaction([selectedJournalRow['accountCode'] = event.data["accountInnerCode"]]);
                    gridOptions2.api.applyTransaction([selectedJournalRow['accountName'] = event.data["accountName"]]);
                    console.log("event.data[accountInnerCode] :" + event.data["accountInnerCode"]);
                    $.ajax({
                        type    : "GET",
                        url     : "${pageContext.request.contextPath}/operate/accountcontrollist",
                        data    : {
                            accountCode: event.data["accountInnerCode"] //이값이 겁색한 값이다. ex)매출
                        },
                        dataType: "json",
                        success : function (jsonObj) {
                            console.log(jsonObj);
                            ///     gridOptions2.api.applyTransaction([selectedJournalRow['journalDetail']=jsonObj['accountControl']]);


                            console.log(selectedJournalRow['journalNo']);
                            console.log(selectedJournalRow);
                            /*jsonObj['accountControl'].forEach(function (element, index) { //분개상세 key값
                                element['journalNo'] = selectedJournalRow['journalNo']; //요소추가?
                            })
                            console.log(jsonObj['accountControl']);
                            gridOptions2.api.applyTransaction([selectedJournalRow['journalDetailList'] = jsonObj['accountControl']]);*/ //돌아가지 않는 로직임,

                            console.log("selectedJournalRow :" + selectedJournalRow);
                            gridOptions2.api.redrawRows(); //행 다시 그리기  -- 굳이 다시 그린 이유는? 바로 위에 지운 로직이랑 관계가 있는 건가?
                        }
                    });
                }
            };
            accountDetailGrid = document.querySelector('#accountDetailGrid');
            new agGrid.Grid(accountDetailGrid, gridOpionsAccountDetail); //div 태그에 붙임
        }
        function showAccountDetail(code) { //code 에 selectedRow["accountInnerCode"] 값 들어감
            console.log("accountInnerCode", code);
            $.ajax({
                type    : "GET",
                url     : "${pageContext.request.contextPath}/operate/detailaccountlist",
                data    : {
                    "code": code
                },
                dataType: "json",
                success : function (jsonObj) {
                    gridOpionsAccountDetail.api.setRowData(jsonObj);
                }
            });
        }
        // 계정과목 클릭시 나오는 모달창과 함께 실행되는 메서드
        function searchAccount() {
            console.log("searchAccount() 실행");
            // show loading message
            $.ajax({
                type    : "GET",
                url     : "${pageContext.request.contextPath}/operate/accountlistbyname",
                data    : {
                    accountName: $("#accountCode").val() //이값이 겁색한 값이다. ex)매출
                },
                dataType: "json",
                success : function (jsonObj) {
                    console.log(JSON.stringify(jsonObj));
                    console.log(JSON.stringify(jsonObj.accountList));
                    gridOpionsAccountDetail.api.setRowData(jsonObj); //내부 상세 그리드(오른쪽)에 값 넣기, gridoption.api.setRowdata실행 시 데이터 세팅함 - 잘못세팅되어있엇는데 고쳐놓음
                    $("#accountCode").val(""); // 검색한다음에 지우기 셋팅(dong)
                }
            });
        }

        //거래처코드
        function searchCustomerCodeList() { // 거래처리스트 불러오기

            $.ajax({
                type    : "POST",
                url     : "${pageContext.request.contextPath}/operate/allworkplacelist",
                //data    : {},
                dataType: "json",
                success : function (jsonObj) {      //제이슨 형식으로 모든 거래처 리스트를 불러온다. 그리고 그걸 gridOptions6의 컬럼에 전부 세팅한다. 나머지는 gridOptions6에서 확인하기!!!!!
                    //console.log("거래처코드 : " +JSON.stringify(jsonObj.allWorkplaceList));
                    gridOptions6.api.setRowData(jsonObj);

                }
            });
        }

        // 계정코드 입력시 계정과목 검색
        function getAccountName(accountCode) {
            console.log("findAccountName(accountCode) 실행");
            $.ajax({
                type    : "GET",
                url     : "${pageContext.request.contextPath}/operate/account",
                data    : {
                    accountCode: accountCode
                },
                dataType: "json",
                success : function (jsonObj) {
                    console.log("계정코드 변경 후 계정과목 변경", jsonObj);
                    var accountName = jsonObj.accountName;
                    gridOptions2.api.applyTransaction([selectedJournalRow['accountName'] = accountName]);
                },
                async   : false
            });
        }

      function cellRenderer(params) {  // 중복되는일이라 불필요(dong)
            console.log("cellRenderer(params) 실행");
            console.log(params);
            var result;
            if (params.value != null){
                result = params.value;
                console.log(result);
            }
            else {
                result = ''
            }
            console.log(result);
            return result;
        }

        var gridOptions5;

        function createCodeGrid() {
            console.log("createCodeGrid() 실행");
            rowData = [];
            var columnDefs = [{
                headerName: "코드",
                field     : "detailCode",
                width     : 100,
                sortable  : true,
            }, {
                headerName: "부서이름",
                field     : "detailCodeName",
                width     : 100,
                sortable  : true,
            }];

            gridOptions5 = {
                columnDefs       : columnDefs,
                rowSelection     : 'single', //row는 하나만 선택 가능
                defaultColDef    : {
                    editable: false
                }, // 정의하지 않은 컬럼은 자동으로 설정
                onGridReady      : function (event) {// onload 이벤트와 유사 ready 이후 필요한 이벤트 삽입한다.
                    event.api.sizeColumnsToFit();
                },
                onGridSizeChanged: function (event) { // 그리드의 사이즈가 변하면 자동으로 컬럼의 사이즈 정리
                    event.api.sizeColumnsToFit();
                },
                onRowClicked     : function (event) {
                    console.log("CodeGrid의 onRowClicked 실행");
                    var detailCodeName = event.data["detailCodeName"]
                    var detailCode = event.data["detailCode"]
                    console.log(detailCodeName);
                    detailGridApi.api.applyTransaction([selectedJournalDetail["journalDescription"] = detailCodeName]); //journalDescription 분개상세내용
                    detailGridApi.api.applyTransaction([selectedJournalDetail["journalDescriptionCode"] = detailCode]);
                    saveJournalDetailRow();
                    gridOptions2.api.getDetailGridInfo('detail_' + selectedJournalRow); //쓰는데가 없는거같은데...
                    $("#codeModal").modal('hide');
                }
            };
            codeGrid = document.querySelector('#codeGrid');
            new agGrid.Grid(codeGrid, gridOptions5);
        }

        //거래처 코드
        var rowDataCode;
        var gridOpions6;

        function createCustomerCodeGrid() {//
            rowDataCode = [];
            var columnDefs = [
                {headerName: "사업장 코드", field: "workplaceCode", width: 100, hide: true},
                {headerName: "거래처 코드", field: "companyCode", width: 100},
                {headerName: "사업장명", field: "workplaceName", width: 100},
                {headerName: "대표자명", field: "workplaceCeoName", width: 100, hide: true},
                {headerName: "업태", field: "businessConditions", width: 100, hide: true},
                {headerName: "사업자등록번호", field: "businessLicense", width: 100},
                {headerName: "법인등록번호", field: "corporationLicence", width: 100, hide: true},
                {headerName: "사업장전화번호", field: "workplaceTelNumber", hide: true},
                {headerName: "승인상태", field: "approvalStatus", width: 100, hide: true},
            ];

            gridOptions6 = {
                columnDefs        : columnDefs,
                rowSelection      : 'single', //row는 하나만 선택 가능
                defaultColDef     : {editable: false}, // 정의하지 않은 컬럼은 자동으로 설정
                pagination        : true, // 페이저
                paginationPageSize: 10, // 페이저에 보여줄 row의 수
                onGridReady       : function (event) {// onload 이벤트와 유사 ready 이후 필요한 이벤트 삽입한다.
                    event.api.sizeColumnsToFit();
                },
                onGridSizeChanged : function (event) { // 그리드의 사이즈가 변하면 자동으로 컬럼의 사이즈 정리
                    event.api.sizeColumnsToFit();
                },


                //cell double click
                onCellDoubleClicked: function (event) {     //거래처코드 모달창의 그리드 셀을 더블클릭시 모달창을 끄면서 내가 선택한 로우의 workplaceName을 selectedJournalRow의 customerName컬럼에 값을 넣는다.
                    $("#customerCodeModalGrid").modal('hide');
                    gridOptions2.api.applyTransaction([selectedJournalRow['customerName'] = event.data["workplaceName"]]);      //api.applyTransaction은 UpdateRowData에서 변경된거라 생각하면 된다.

                }
            };
            customerCodeGrid = document.querySelector('#customerCodeGrid');
            new agGrid.Grid(customerCodeGrid, gridOptions6);
        }

        //분개 상세 부서조회에서의 코드조회  - 분개 상세의 하위 그리드 더블클릭 시 계정 설정 에서 search일때 더블킬릭하면 실행되는 메서드
        function searchCode() {
            console.log("searchCode 실행");
            $.ajax({
                type    : "GET",
                url     : "${pageContext.request.contextPath}/base/detailcodelist",
                data    : {
                    divisionCodeNo: selectedJournalDetail["accountControlDescription"], //accountControlDescription = ACCOUNT_CONTROL_DETAIL의 Description
                    detailCodeName: $("#searchCode").val() //부서 입력한 값
                },
                dataType: "json",
                success : function (jsonObj) {
                    console.log(jsonObj);
                    gridOptions5.api.setRowData(jsonObj);
                    $("#searchCode").val("");
                },
                async   : false
            });
        }


        function selectBank() { //분개상세 그리드의 하위 그리드의 계정설정속성값이 select 일때, 셀 아무거나 두번 클릭했을 시 발생하는 메서드. 분개상세내용의 값에 옵션을 주도록 만들어둠,
                                //그런 다음 saveJournalDetailRow 메서드 실행
            console.log("selectBank() 실행");
            ele = document.createElement("select");
            ele.id = "selectId"
            $.ajax({
                type    : "GET",
                url     : "${pageContext.request.contextPath}/base/detailcodelist",
                data    : {
                    divisionCodeNo: selectedJournalDetail["accountControlDescription"]
                },
                dataType: "json",
                async   : false,
                success : function (jsonObj) {
                    console.log("selectBank의 jsonObj"+jsonObj);
                    console.log(jsonObj);
                    $("<option></option>").appendTo(ele).html(''); //옵션 값 초기화
                    $.each(jsonObj, function (index, obj) {
                        $("<option></option>").appendTo(ele).html(obj.detailCodeName);
                    });
                }
            });

            $(ele).change(function () {
                console.log("$(ele).change 실행");
                console.log($(this).val());
                detailGridApi.api.applyTransaction([selectedJournalDetail["journalDescription"] = $(this).children("option:selected").text()]);
                detailGridApi.api.applyTransaction([selectedJournalDetail["journalDescriptionCode"] = $(this).val()]);//내가 옵션에서 선택한 값을 숨겨진 journalDescriptionCode 항목에 저장해둠
                saveJournalDetailRow();
            })

            return ele;
        }

        function selectCal() {
            console.log("selectCal 실행");
            ele = document.createElement("input");
            ele.type = "date"
            $(ele).change(function () {
                detailGridApi.api.applyTransaction([selectedJournalDetail["journalDescription"] = $(ele).val()]);
                saveJournalDetailRow();
            })
            return ele;
        }


        function saveJournalDetailRow() {
            console.log("saveJournalDetailRow() 실행");
            console.log(selectedJournalRow);
            var rjournalDescription;
            if (selectedJournalDetail["accountControlType"] == "SELECT" || selectedJournalDetail["accountControlType"] == "SEARCH")
                rjournalDescription = selectedJournalDetail["journalDescriptionCode"]; //- 숨겨진 곳에 저장한 값

            else
                rjournalDescription = selectedJournalDetail["journalDescription"];//어차피 위에것과 아래것 둘다 값 같음, 왜 이렇게 해두었을까? 아마 search부분에 답이있을듯?

            $.ajax({
                type    : "GET",
                url     : "${pageContext.request.contextPath}/posting/journaldetailmodification",
                data    : {
                    journalNo         : selectedJournalRow["journalNo"],
                    accountControlType: selectedJournalDetail["accountControlType"],
                    journalDetailNo   : selectedJournalDetail["journalDetailNo"],
                    journalDescription: rjournalDescription
                },
                dataType: "json",
                //async   : false,//비동기식으로 작동시켜놨는데, 그냥 동기식으로 해놓으면 됨, false 에서 true로 바꿔놈
                complete : function () {//데이터 받을 게 없기때문에 완료만되면 무조건 실행하는 complete로 바꿔둠
                    console.log("분개 상세  저장 성공");//이까지가 되야 전부 journal_detail 테이블에 내용 바뀜
                }
            });
        }

        /*분개 합계 계산*/

        function computeJournalTotal() {

            console.log("computeJournalTotal 실행");
            var totalIndex = (gridOptions2.api.getDisplayedRowCount())-1; //분개 그리드의 총 행 갯수를 가져오고 -1을 한다, -1을 하는 이유는 Total 값 가져와야됨
            console.log("totalIndex",totalIndex)

            //표시된 행의 총 수를 반환합니다.
            var totalRow = gridOptions2.api.getDisplayedRowAtIndex(totalIndex);

            console.log("totalRow",totalRow)
            console.log("totalRow :" + JSON.stringify(totalRow.data));
            //지정된 인덱스에 표시된 RowNode를 반환합니다. 즉 마지막 total의 정보를 담고있음
            var leftDebtorTotal = 0;
            var rightCreditsTotal = 0;

            gridOptions2.api.forEachNode(function (node, index) {

                console.log(node);
                console.log(parseInt(node.data.leftDebtorPrice));
                console.log(parseInt(node.data.rightCreditsPrice));
                if (node != totalRow) {
                    if (node.journalNO != "Total") { //node.journalNO는 애초에 undefined인데? 그냥 없는게 나은 코드임
                        leftDebtorTotal += parseInt(node.data.leftDebtorPrice);
                        rightCreditsTotal += parseInt(node.data.rightCreditsPrice);
                    }
                }
            });
            totalRow.setDataValue('leftDebtorPrice', leftDebtorTotal);
            totalRow.setDataValue('rightCreditsPrice', rightCreditsTotal);
            /*debugger*/
            console.log(totalRow.data.leftDebtorPrice);
            console.log(totalRow.data.rightCreditsPrice);
            console.log(totalRow);
            console.log("합계산 끝")
        }


        // 거래처 그리드 생성


    </script>
</head>
<%---------------------------------body부분------------------------------------------%>
<body class="bg-gradient-primary">
<h4>전표</h4>
<hr>
<div class="row">

    <input id="from" type="date" class="date" required style="margin-left:12px;">
    <input id="to" type="date" class="date" required>
    <select id="selTag" class="date" id="selTag">
        <option>승인여부</option>
        <option>작성중</option>
        <option>승인요청</option>
        <option>승인완료</option>
        <option>작성중(반려)</option>
    </select>
    <input type="button" id="search" value="검색" class="btn btn-Light shadow-sm btnsize2"
           style="margin-left:5px;">
</div>

<div>
    <%---------------------------------------버튼들------------------------------------%>
    <div style="text-align:right;">
        <input type="button" id="addSlip" value="전표 추가(F2)" class="btn btn-Light shadow-sm btnsize">
        <input type="button" id="deleteSlip" value="전표 삭제" class="btn btn-Light shadow-sm btnsize">
        <input type="button" id="showPDF" value="PDF보기" class="btn btn-Light shadow-sm btnsize">
        <input type="button" id="saveSlip" value="전표 저장(F3)" class="btn btn-Light shadow-sm btnsize">
        <input type="button" id="confirm" value="결재 신청(F4)" class="btn btn-Light shadow-sm btnsize">
ㅏ
    </div>
   </div>
<!-- 전표 그리드 -->
<div align="center"> <!-- 셀정렬 -->
    <div id="slipGrid" class="ag-theme-balham" style="height:250px;width:auto;"></div>
</div>
<hr/>
<h3>분개</h3>
<!-- 분개 그리드 -->
<div align="right">
    <input type="button" id="addJournal" value="분개 추가" class="btn btn-Light shadow-sm btnsize">
    <input type="button" id="deleteJournal" value="분개 삭제" class="btn btn-Light shadow-sm btnsize">
    <div id="journalGrid" class="ag-theme-balham" style="height:450px;width:auto;"></div>
</div>

<!-- journalGrid의 그리드 내용인 gridOption2에 oncellclicked 메서드 걸려있음, cell누르자마자 clicked안의 모달.show메서드 실행. 모달 보며주면서 아래 연결된 메서드 같이 실행 -->
<!-- 계정과목 직접입력 후 검색 기능 안됨 - 고침 -->
<div class="modal fade" id="accountGridModal" tabindex="-1" role="dialog"
     aria-labelledby="accountGridLabel" style="padding-right: 210px;">
    <div class="modal-dialog" role="document">
        <div class="modal-content" style="width: 645px; margin-top: 130px">
            <div class="modal-header">
                <h5 class="modal-title" id="accountGridLabel">계정 코드 조회</h5>
                <button class="close" type="button" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">×</span>
                </button>
            </div>
            <div class="modal-header">
                <input type="text" class="form-control bg-light border-0 small" placeholder="계정과목을 입력해주세요"
                       id="accountCode" aria-label="AccountSearch" aria-describedby="basic-addon2">
                <div class="input-group-append">
                    <button class="btn btn-primary" type="button" id="Accountbtn">
                        <i class="fas fa-search fa-sm"></i>
                    </button>
                </div>
            </div>
            <div class="modal-body">
                <div style="float: left; width: 50%;">
                    <div align="center"> <!-- 셀 정렬 -->
                        <div id="accountGrid" class="ag-theme-balham"
                             style="height: 500px; width: 100%; margin-left:-10px;"></div>
                    </div>
                </div>

                <div style="float: left; width:50%;">
                    <div align="center"> <!-- 셀 정렬 -->
                        <div id="accountDetailGrid" class="ag-theme-balham"
                             style="height: 500px; width: 100%; margin-left:5px;"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<!-- gridOption4를 사용한 분개상세쪽 grid인데 사용안하고있음, 사용하고잇엇는대 내가 못찾은거였음 근데 어케 띄워야할지 모름, 하위 그리드의 계정설정 속성을 search로 바꾸면 뜨는데 어떻게 바꿔야할지 찾아봐야할듯-->
<div align="center" class="modal fade" id="codeModal" tabindex="-1" role="dialog"
     aria-labelledby="codeLabel">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="codeLabel">부서 코드 조회</h5>
                <button class="close" type="button" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">×</span>
                </button>
            </div>
            <div class="modal-header">
                <input type="text" class="form-control bg-light border-0 small" placeholder="부서를 입력해주세요"
                       id="searchCode" aria-label="deptSearch" aria-describedby="basic-addon2">
                <div class="input-group-append">
                    <button class="btn btn-primary" type="button" id="searchCodebtn">
                        <i class="fas fa-search fa-sm"></i>
                    </button>
                </div>
            </div>
            <div class="modal-body">
                <div align="center" id="codeGrid" class="ag-theme-balham" style="width:auto;height:150px">
                </div>
            </div>
        </div>
    </div>
</div>
<!-- 거래처 모달창 -->
<div align="center" class="modal fade" id="customerCodeModalGrid" tabindex="-1" role="dialog"
     aria-labelledby="customerCodeModalGrid">
    <div class="modal-dialog" role="document">
        <div class="modal-content" style="width:700px;">
            <div class="modal-header">
                <h5 class="modal-title" id="customerCodeModalLabel">거래처 코드</h5>
                <button class="close" type="button" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">×</span>
                </button>
            </div>
            <div class="modal-body">

                <div align="center"> <!-- 셀 정렬 -->
                    <div id="customerCodeGrid" class="ag-theme-balham"
                         style="height: 500px; width: 100%; margin-left:-10px;"></div>
                </div>


            </div>
        </div>
    </div>
</div>


</body>

</html>

<!--
/***********************************************************************************
SELECT * FROM JOURNAL;
SELECT * FROM JOURNAL_DETAIL;
SELECT * FROM ACCOUNT_CONTROL_CODE;
SELECT * FROM ACCOUNT_CONTROL_DETAIL;
SELECT * FROM CODE_DETAIL;


SELECT * FROM MENU_AVAILABLE_BY_POSITION;
SELECT * FROM POSITION;
SELECT * FROM AUTHORITY_EMP;
SELECT * FROM AUTHORITY;
SELECT * FROM AUTHORITY_MENU;
SELECT * FROM MENU
SELECT * FROM MENU_AVAILABLE_BY_POSITION
SELECT * FROM POSITION
SELECT * FROM EMPLOYEE


************************************************************************************/ -->