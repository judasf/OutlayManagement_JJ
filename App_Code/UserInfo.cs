using System;
using System.Collections.Generic;
using System.Web;

/// <summary>
///UserInfo表实体类
/// </summary>
public class UserInfo
{
    private int _uid;
    /// <summary>
    /// 用户UID
    /// </summary>
    public int UID
    {
        get { return _uid; }
        set { _uid = value; }
    }
    
    private string _userNum;
    /// <summary>
    /// 用户编号
    /// </summary>
    public string UserNum
    {
        get { return _userNum; }
        set { _userNum = value; }
    }
    private string _userName;
    /// <summary>
    /// 用户名
    /// </summary>
    public string UserName
    {
        get { return _userName; }
        set { _userName = value; }
    }
    private string _userDept;
    /// <summary>
    /// 用户所在单位名称（针对基层用户，其他用户没有单位信息设置为“0”）
    /// </summary>
    public string UserDept
    {
        get { return _userDept; }
        set { _userDept = value; }
    }
    private int _deptId;
    /// <summary>
    /// 用户所在单位编号（针对基层用户，其他用户单位编号为0）
    /// </summary>
    public int DeptId
    {
        get { return _deptId; }
        set { _deptId = value; }
    }
    private int _roleId;
    /// <summary>
    /// 用户角色编号，对应用户权限信息
    /// </summary>
    public int RoleId
    {
        get { return _roleId; }
        set { _roleId = value; }
    }
    private string _roleName;
    /// <summary>
    /// 用户角色名称
    /// </summary>
    public string RoleName
    {
        get { return _roleName; }
        set { _roleName = value; }
    }
    private string _scopeDepts;
    /// <summary>
    /// 用户管辖范围，默认为0，基层用户指自己，其他用户指全部基层单位，若不为0可获取管辖单位信息(1,2,3,4)
    /// </summary>
    public string ScopeDepts
    {
        get { return _scopeDepts; }
        set { _scopeDepts = value; }
    }
    private string _userStatus;
    /// <summary>
    /// 用户状态，默认0：正常，1：锁定，针对一般用户
    /// </summary>
    public string UserStatus
    {
        get { return _userStatus; }
        set { _userStatus = value; }
    }
	public UserInfo()
	{
	}
}