package kr.co.seoulit.account.posting.business.controller;

import java.io.IOException;
import java.io.PrintWriter;

import java.util.ArrayList;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.ModelAndView;

import kr.co.seoulit.account.posting.business.service.BusinessService;
import kr.co.seoulit.account.posting.business.service.BusinessServiceImpl;
import kr.co.seoulit.account.posting.business.to.JournalDetailBean;
import kr.co.seoulit.account.sys.common.exception.DataAccessException;
import net.sf.json.JSONObject;

@RestController
@RequestMapping("/posting")
public class JournalDetailController {

	@Autowired
	private BusinessService businessService;

	ModelAndView mav = null;
	ModelMap map = new ModelMap();

	@GetMapping("/journaldetaillist")
	public ArrayList<JournalDetailBean> findJournalDetailList(@RequestParam String journalNo) {

		ArrayList<JournalDetailBean> journalDetailList = businessService.findJournalDetailList(journalNo);

		return journalDetailList;
	}

	@GetMapping("/journaldetailmodification")
	public void modifyJournalDetail(@RequestParam String accountControlType, @RequestParam String journalNo,
			@RequestParam(value = "journalDetailNo", required = false) String journalDetailNo,
			@RequestParam String journalDescription) {

		JournalDetailBean journalDetailBean = new JournalDetailBean();

		journalDetailBean.setAccountControlType(accountControlType);
		journalDetailBean.setJournalNo(journalNo);
		journalDetailBean.setJournalDetailNo(journalDetailNo);
		journalDetailBean.setJournalDescription(journalDescription);

		businessService.modifyJournalDetail(journalDetailBean);

	}
//        ?????? modify ?????? ???????????? ?????? ??? ????????? ??????????????? ?????? ?????????(choi)

}
